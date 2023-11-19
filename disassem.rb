# Initialization
require 'enumerator'

# get C program name
program_name = ARGV[0]
if program_name == nil
    puts "No program"
    exit
end

# Output: objdump.txt
# Command: objdump -d ARGV[0]
objdump = "objdump -d #{program_name}"

# Output: llvm-dwarfdump.txt
# Command: llvm-dwarfdump --debug-line ARGV[0]
dwarfdump = "llvm-dwarfdump --debug-line #{program_name}"
obj = `#{objdump}`
dwarf = `#{dwarfdump}`
# puts "This is objDump result:"
# puts obj
# puts "This is dwarf result:"
# puts dwarf

# make files
dwarfdump_file = "llvm-dwarfdump.txt"
objdump_file = "objdump.txt"

# write into file
File.open(dwarfdump_file, 'w') do |file|
  file.puts dwarf
end

File.open(objdump_file, 'w') do |file|
  file.puts obj
end

# create a corresponding html file
html_file = "#{program_name}_disassem.html"

# use the template in the directory
html_template = File.read("template.html")

# putting stuff in template:
# open source code file
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
  finalSourceCode << "<button>&nbsp;&nbsp;#{lineNum}</button> <span id=\"s1\" aline=\"\" style=\"background-color: white;\">#{cleaned_line}</span>\n"
  lineNum = lineNum + 1

end

html_template.gsub!('{line_placeholder}', finalSourceCode)
# puts finalSourceCode

file.close

# html_template.gsub!('<%= program_name %>', program_name)
# html_template.gsub!('<%= obj_dump_result %>', File.read(objdump_file))
# html_template.gsub!('<%= dwarfdump_result %>', File.read(dwarfdump_file))

# open file we created and write the template do it.
File.open(html_file, 'w') do |file|
  file.puts html_template
end

# 
















