#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

flowcell_id = ARGV[0]
@test = true

output_filename = "run_align_step.out"

@output_file = File.new(output_filename, 'w')

def output message
  @output_file << message << "\n"
  puts message
end

def execute command
  output command
  system(command) unless @test
end

output "starting alignment step for #{flowcell_id}"
Illuminati::Emailer.email "starting align step for #{flowcell_id}" unless @test
Illuminati::SolexaLogger::log flowcell_id, "starting alignment", @test

flowcell = nil

begin
  flowcell = Illuminati::FlowcellData.new(flowcell_id)
rescue Exception => err
  output "Problem creating flowcell"
  output "Flowcell id: #{flowcell_id}."
  output err
end

if flowcell
  config_file = File.join(flowcell.base_dir, "config.txt")
  if File.exists? config_file
    command = "#{CASAVA_PATH}/configureAlignment.pl #{config_file}"
    execute command
    command += " --make"
    execute command

    command = "cd #{flowcell.aligned_dir};"
    command += " nohup make -j 8 all > make.aligned.out 2>&1  &"
    execute command

  else
    output "ERROR: no config.txt file found in #{flowcell.base_dir}"
  end
end

output "Done"
@output_file.close