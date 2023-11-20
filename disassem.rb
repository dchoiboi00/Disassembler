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

  finalSourceCode << "<button>#{spacesBeforeNum}#{lineNum}</button> <span id=\"s#{lineNum}\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"
  
  lineNum = lineNum + 1

end
file.close
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


File.open("#{dwarfdump_file}", "r") do |file|

  at_table = false
  file.each_line do |line|


    if at_table
      puts "#{line}"
      # 
    end

    
    if line.start_with?("------------------")
      # lines_starting_with_dash << line
      # set scanning to true
      at_table = true
      
    end
  end
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
# html_template.gsub!('{assembly_code_placeholder}', finalAssemblyCode)

# open file we created and use the html template we just manipulated.

File.open(html_file, 'w') do |file|
  file.puts html_template
end

# 
















