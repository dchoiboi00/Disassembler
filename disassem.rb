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

# Parse function names
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


# Begin mapping sline -> aline and aline -> sline
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

lenghtOfArray = number_array.length


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
  no_space_line = line.chomp
  cleaned_line = no_space_line&.gsub(/</, '&lt;')&.gsub(/>/, '&gt;')

  

  spacesBeforeNum =
    if lineNum < 10
      "&nbsp;&nbsp;"
    elsif lineNum < 100
      "&nbsp;"
    else
      ""
    end

  if number_array.include?(lineNum)

    # whole array
    aline_value = ""
    # find min
    for_sclick = ""
    # get a->[], where [] is list of source line a points to
    
    sline_to_alines_int_array = sline_to_alines["s#{lineNum}"]
    
    sline_to_alines_int_array.each do |element|
      aline_value << "#{element} "
    end  

    for_sclick << sline_to_alines_int_array.min

    
    finalSourceCode << "<button onclick=\"sclick(\'s#{lineNum}\',\'#{for_sclick}\')\">#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"#{aline_value}\" style=\"background-color: white;\">#{cleaned_line}</span>\n"

  else 
    finalSourceCode << "<button>#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"
  end

  lineNum = lineNum + 1

  

end
file.close

assembly_HTML = ""
assembly_count = 1
function_array.each do |func|
  # insert html element here
  assembly_HTML << "#{func.chomp.gsub!(/</, '&lt;').gsub!(/>/, '&gt;')}\n\n"

  
  # for each line in assem_code_by_func[func]
  assem_code_by_func[func].each do |line|
  # split the line into what we need
  lineArray = line.split
  # 0 - address  1 - code

  a_addy = lineArray[0].gsub(/:.*/, '')
  a_code = assem_address_to_line_and_code[a_addy][1].match(/:\s*(.*)/)&.captures&.first
  
  
  sline_value = ""
  for_aclick = ""
  # get a->[], where [] is list of source line a points to
  
  aline_to_slines_int_array = aline_to_slines["a#{assembly_count}"]
  
  aline_to_slines_int_array.each do |element|
    sline_value << "#{element} "
  end  

  for_aclick << aline_to_slines_int_array.min
  
  # puts "#{assembly_count} #{a_code}"
  assembly_HTML << "<button onclick=\"aclick(\'a#{assembly_count}\',\'#{for_aclick}\')\">#{a_addy}</button><span id=\"a#{assembly_count}\" sline=\"#{sline_value}\"> #{a_code}</span>\n"

  assembly_count = assembly_count + 1

  end
  assembly_HTML << "\n"
end


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
