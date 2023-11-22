# Initialization
require 'enumerator'

# get C program name
program_name = ARGV[0]
if program_name == nil
    puts "No program"
    exit
end

# making commands
# Output: objdump.txt
# Command: objdump -d ARGV[0]
objdump = "objdump -d #{program_name}"

# Output: llvm-dwarfdump.txt
# Command: llvm-dwarfdump --debug-line ARGV[0]
dwarfdump = "llvm-dwarfdump --debug-line #{program_name}"

# execute shell commands
obj = `#{objdump}`
dwarf = `#{dwarfdump}`
# puts "This is objDump result:"
# puts obj
# puts "This is dwarf result:"
# puts dwarf


# Part 1: source code scraper
# open source code file
# TODO:
# -Think about the sclick="" for each button

# begin
#   file = File.open("#{program_name}.c", "r")
# rescue Errno::ENOENT
#   puts "Source code file not found"
#   exit
# end

# lineNum = 1
# finalSourceCode = ""
# file.each_line do |line|
#   # puts "#{lineNum}#{line}"
#   # remove new line from line
#   cleaned_line = line.chomp 

#   spacesBeforeNum =
#     if lineNum < 10
#       "&nbsp;&nbsp;"
#     elsif lineNum < 100
#       "&nbsp;"
#     else
#       ""
#     end

#   finalSourceCode << "<button>#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"
  
#   lineNum = lineNum + 1

# end
# file.close
# puts finalSourceCode

# source code scraper done 



# TODO
# Part 2: assembly code scraper 

# make the txt files needed
dwarfdump_file = "llvm-dwarfdump.txt"
objdump_file = "objdump.txt"

# write into file
File.open(dwarfdump_file, 'w') do |file|
  file.puts dwarf
end

File.open(objdump_file, 'w') do |file|
  file.puts obj
end

# use obj and dwarf to come up with html 
# dwarf and obj are string
# dwarf gives me the line of source code and assembly address

finalAssemblyCode = ""

# puts dwarf

# The table at the end of dwarf, we want the first two columns of that table, go through the whole table
# Address is sorted by assembly code address (column 1)
# 

number_array = []
all_functions_array = []
all_func_addresses = []
function_array = [] # contains the functions we need to display

# Create an array of all function + addresses from objdump
obj.each_line do |line|
  if line.match(/[\d+]* <[^>]*>:/)
    all_functions_array.push(line)
    all_func_addresses.append(line.split[0][-6..-1])
  end
end

# Get lines that we need from dwarfdump
dwarf_lines = []
dwarf.each_line do |line|
  if line.match(/^0x/)
    if line.split[6] != "end_sequence"
      dwarf_lines.push(line)
    end
  end
end

# Change file 2 line_num to most previous file 1
last_sline = ""
dwarf_lines.each do |line|
  if line.split[3] == "1"
    last_sline = line.split[1]
  end
  if line.split[3] != "1"
    replace_num = line.split[1]
    line.gsub!(/\s#{replace_num}/, last_sline)
  end
end

# Testing: replace file 2 line_num columns with previous file 1's line num
puts "New dwarfdump, replaced file 2 line nums"
puts dwarf_lines, "\n"

# Find functions
dwarf_lines.each do |line|
  # parse line by space
  line_array = line.split
  source_line_num = line_array[1].to_i
  address = line_array[0][-6..-1]
  
  number_array.push(source_line_num)

  # check if address is a function in objdump
  all_func_addresses.each_with_index do |curr_addy, index|
    if curr_addy == address
      if !function_array.include?(all_functions_array[index])
        function_array.push(all_functions_array[index])
      end
    end
  end
end

# store hashmap: func_name -> [assemb_line1, assemb_line2, ...]
assem_code_by_func = {}
File.open("#{objdump_file}", "r") do |file|
  function_array.each do |func|
    assem_code_by_func[func] = []
    nextline = file.gets
    while nextline != func
      nextline = file.gets
    end
    nextline = file.gets
    while nextline.match(/\s+\w{6}:/)  # match "  401196: ..."
      assem_code_by_func[func].push(nextline)
      nextline = file.gets
    end
  end
end

# testing, it works!
# function_array.each do |func|
#   puts func
#   puts assem_code_by_func[func]
# end

# build a1 -> 401235
# build 401235 -> [a1, code]
assem_line_to_address = {}
assem_address_to_line_and_code = {}
index = 1
function_array.each do |func|
  assem_code_by_func[func].each do |line|
    aline = "a" + index.to_s
    address = line[2..7]
    assem_line_to_address[aline] = address
    assem_address_to_line_and_code[address] = [aline, line]
    index = index + 1
  end
end
max_aline = index - 1


aline_to_slines = {}
sline_to_alines = {}
prev_sline = ""
prev_aline = ""
sline = ""
aline = ""

# map s36 -> [a1, a2]
# map a1 -> [s36]
dwarf_lines.each_with_index do |line, index|
  address = line.split[0][-6..-1]
  sline = "s" + line.split[1]

  aline = assem_address_to_line_and_code[address][0]

  # skip if duplicate line
  if prev_sline == sline && prev_aline == aline
    next
  end

  # Store sline -> aline, aline -> sline
  if sline_to_alines.include?(sline)
    if !sline_to_alines[sline].include?(aline)
      sline_to_alines[sline].push(aline)
    end
  else
    sline_to_alines[sline] = [aline]
  end
  
  if aline_to_slines.include?(aline)
    if !aline_to_slines[aline].include?(sline)
      aline_to_slines[aline].push(sline)
    end
  else
    aline_to_slines[aline] = [sline]
  end
  
  if index != dwarf_lines.length() - 1
    # Find next sline that is different, add assem addresses to sline up until that address
    i = 1
    next_sline = dwarf_lines[index+i]
    while "s" + next_sline.split[1] == sline
      i = i + 1
      if index + i == dwarf_lines.length()
        break
      end
      next_sline = dwarf_lines[index+i]
    end
    end_address = next_sline.split[0][-6..-1]
    
    # add all assem address up to end_address (non-inclusive)
    start_aline = aline[1..-1].to_i + 1
    end_aline = assem_address_to_line_and_code[end_address][0][1..-1].to_i - 1
    for i in start_aline..end_aline
      add_aline = "a" + i.to_s
      # Store sline -> aline, aline -> sline
      if sline_to_alines.include?(sline)
        if !sline_to_alines[sline].include?(add_aline)
          sline_to_alines[sline].push(add_aline)
        end
      else
        sline_to_alines[sline] = [add_aline]
      end
      
      if aline_to_slines.include?(add_aline)
        if !aline_to_slines[add_aline].include?(sline)
          aline_to_slines[add_aline].push(sline)
        end
      else
        aline_to_slines[add_aline] = [sline]
      end
    end

  # If last line
  else
    start_aline = aline[1..-1].to_i + 1
    for i in start_aline..max_aline
      add_aline = "a" + i.to_s
      # Store sline -> aline, aline -> sline
      if sline_to_alines.include?(sline)
        if !sline_to_alines[sline].include?(add_aline)
          sline_to_alines[sline].push(add_aline)
        end
      else
        sline_to_alines[sline] = [add_aline]
      end
      
      if aline_to_slines.include?(add_aline)
        if !aline_to_slines[add_aline].include?(sline)
          aline_to_slines[add_aline].push(sline)
        end
      else
        aline_to_slines[add_aline] = [sline]
      end
    end
  end


  prev_sline = sline
  prev_aline = aline
end

# UP TO HERE, MAPPING DONE
puts "Source to assembly mappings"
puts sline_to_alines
puts "\nAssembly to source mappings"
puts aline_to_slines



lenghtOfArray = number_array.length
# puts "Number Array here: #{number_array} #{lenghtOfArray}"


# Source code section making
begin
  file = File.open("#{program_name}.c", "r")
rescue Errno::ENOENT
  puts "Source code file not found"
  exit
end

lineNum = 1
finalSourceCode = ""
file.each_line do |line|
  # puts "#{lineNum}#{line}"
  # remove new line from line
  cleaned_line = line.chomp 

  spacesBeforeNum =
    if lineNum < 10
      "&nbsp;&nbsp;"
    elsif lineNum < 100
      "&nbsp;"
    else
      ""
    end

  if number_array.include?(lineNum)
    finalSourceCode << "<button onclick=\"sclick(\'s#{lineNum}\',\'a1\')\">#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"

  else 
    finalSourceCode << "<button>#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"
  end

  lineNum = lineNum + 1

  

end
file.close


# assembly section inserting
# do HTML insertion here:
# For each function_array

  puts "\n\n"

assembly_HTML = ""
assembly_count = 1
function_array.each do |func|
  # insert html element here
  # puts func
  puts func.chomp
  assembly_HTML << "#{func.chomp.gsub!(/</, '&lt;').gsub!(/>/, '&gt;')}\n\n"
  # puts assem_code_by_func[func]
  # puts assem_address_to_line_and_code["401196"]
  
  # for each line in assem_code_by_func[func]
  assem_code_by_func[func].each do |line|
  # split the line into what we need
  lineArray = line.split
  # 0 - address  1 - code
  a_addy = lineArray[0].gsub(/:.*/, '')
  a_code = assem_address_to_line_and_code[a_addy][1].match(/:\s*(.*)/)&.captures&.first
  
  # puts "#{assembly_count} #{a_code}"
  assembly_HTML << "<button onclick=\"aclick(\'a#{assembly_count}\',\'s36\')\">#{a_addy}</button><span id=\"#{assembly_count}\" sline=\"s36\"> #{a_code}</span>\n"
  
  

  
  # insert html element here
  # puts "#{assembly_count} #{line}"
  assembly_count = assembly_count + 1


  end
  assembly_HTML << "\n"
  # puts assem_code_by_func[func]



  
end



# html_template.gsub!('<%= program_name %>', program_name)
# html_template.gsub!('<%= obj_dump_result %>', File.read(objdump_file))
# html_template.gsub!('<%= dwarfdump_result %>', File.read(dwarfdump_file))

# create a corresponding html file
html_file = "#{program_name}_disassem.html"

# use the template in the directory
html_template = File.read("template.html")

# putting stuff in template:
# replace placeholder from template with what we just came up with
html_template.gsub!('{source_code_placeholder}', finalSourceCode)
html_template.gsub!('{assembly_code_placeholder}', assembly_HTML)

# open file we created and use the html template we just manipulated.

File.open(html_file, 'w') do |file|
  file.puts html_template
end

# 
















