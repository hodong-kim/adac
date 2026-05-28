# ============================================================================
# Rakefile
# Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
# SPDX-License-Identifier: 0BSD
# ============================================================================

require "rake/file_list"

BUILD_DIR = "obj"
BIN_DIR   = "bin"

task :default => :build

task :build do
  sh "gprbuild -P adac.gpr"
end

task :run => :build do
  sh "./#{BIN_DIR}/adac"
end

task :test => :build do
  FileList["tests/*"].each do |dir|
    input  = "#{dir}/input.adb"
    actual = "#{dir}/actual.txt"
    expect = "#{dir}/expected.txt"
    status = "#{dir}/expected-status.txt"

    puts "==> #{dir}"

    retval = system("./bin/adac #{input} -o #{dir}/main > #{actual}")

    actual_status =
      if retval
        "0"
      else
        "1"
      end

    expected_status = File.read(status).strip

    if actual_status != expected_status
      message =
        "unexpected exit status for #{dir}: " \
        "expected #{expected_status}, " \
        "got #{actual_status}"

      abort(message)
    end

    sh "diff -u #{expect} #{actual}"

    if expected_status == "0"
      asm_path = "#{dir}/main.s"
      exe_path = "#{dir}/main"

      unless File.exist?(asm_path)
        abort("missing assembly output for #{dir}: #{asm_path}")
      end

      sh "cc -o #{exe_path} #{asm_path}"

      unless File.exist?(exe_path)
        abort("missing executable output for #{dir}: #{exe_path}")
      end

      sh exe_path
    end
  end
end

task :style => :build do
  files = FileList[
    "src/**/*.adb",
    "src/**/*.ads",
    "*.gpr",
    "Rakefile"
  ]

  sh "./bin/adac-style #{files.join(' ')}"
end

task :check => [:test, :style]

task :clean do
  sh "gprclean -P adac.gpr"

  rm_f "main.s"

  FileList["tests/**/actual.txt"].each do |path|
    rm_f path
  end

  FileList["tests/**/*.s", "tests/**/main"].each do |path|
    rm_f path
  end
end

desc "Aggregates specified directories or files into a single output text file."
task :plat do
  targets = ARGV.drop(1)
  abort "Usage: rake plat <target1> [target2 ...]" if targets.empty?

  stamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
  output = "#{stamp}.txt"

  files = targets.flat_map do |t|
    if File.file?(t)
      t
    elsif File.directory?(t)
      Dir.glob("#{t}/**/*").select { |f| File.file?(f) }
    else
      puts "Warning: Target not found or invalid - #{t}"
      []
    end
  end.uniq

  abort "No files found in #{targets.join(', ')}." if files.empty?

  File.open(output, "w") do |f|
    files.each do |path|
      f.puts "=" * 80
      f.puts "File: #{path}"
      f.puts "=" * 80
      begin
        f.puts File.read(path)
      rescue => e
        f.puts "-- I/O Error: #{e.message} --"
      end
      f.puts "\n\n"
    end
  end
  puts "Aggregation complete: #{output}"

  # Prevents Rake from treating following arguments as tasks.
  exit 0
end

task :rebuild => [:clean, :build]
