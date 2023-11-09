# Initialization
require 'enumerator'
program_name = ARGV[0]
if program_name == nil
    puts "No program"
    exit
end

objdump = "objdump -d #{program_name}"
dwarfdump = "llvm-dwarfdump --debug-line #{program_name}"
obj = `#{objdump}`
dwarf = `#{dwarfdump}`
puts obj