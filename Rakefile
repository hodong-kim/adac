# ============================================================================
# Rakefile
# Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
# SPDX-License-Identifier: 0BSD
# ============================================================================

require "fileutils"
require "open3"
require "rake/file_list"
require "rbconfig"
require "shellwords"

include FileUtils

SRC_TOP      = __dir__
PROJECT     = File.join(SRC_TOP, "adac.gpr")
BUILD_ROOT  = "build"

SUPPORTED_TARGET_OS = %w[freebsd linux darwin windows android].freeze
SUPPORTED_PROFILES  = %w[debug release].freeze

def fail_config(message)
  abort "ERROR: #{message}"
end

def env_choice(primary, alias_name = nil, default = nil)
  primary_value = ENV[primary]
  alias_value   = alias_name ? ENV[alias_name] : nil

  if primary_value && alias_value && primary_value != alias_value
    fail_config "#{primary} and #{alias_name} disagree"
  end

  primary_value || alias_value || default
end

def command_words(value)
  words = Shellwords.split(value.to_s)
  fail_config "empty command" if words.empty?
  words
end

def capture_command(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return stdout.strip if status.success?

  fail_config "command failed: #{command.join(' ')}\n#{stderr}"
end

def find_program(name)
  return name if name.include?(File::SEPARATOR) && File.executable?(name)

  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
    path = File.join(dir, name)
    return path if File.executable?(path)
  end

  nil
end

def infer_target_os(target)
  value = target.to_s.downcase

  return "android" if value.include?("android")
  return "freebsd" if value.include?("freebsd")
  return "linux"   if value.include?("linux")
  return "darwin"  if value.include?("darwin") || value.include?("apple")
  return "windows" if value.include?("mingw") ||
                      value.include?("windows") ||
                      value.include?("win32")

  nil
end

def normalize_target_os(value)
  return nil if value.nil?

  os = infer_target_os(value) || value.downcase
  return os if SUPPORTED_TARGET_OS.include?(os)

  nil
end

def infer_arch(target)
  arch = target.to_s.split("-").first.to_s.downcase

  case arch
  when "amd64"
    "x86_64"
  when "arm64"
    "aarch64"
  else
    arch
  end
end

def os_version(target, target_os)
  pattern = /#{Regexp.escape(target_os)}([0-9][0-9.]*)?/
  match = target.to_s.downcase.match(pattern)
  return nil unless match

  match[1]
end

def target_abi(target, target_os)
  value = target.to_s.downcase

  case target_os
  when "linux"
    return "musl"     if value.include?("musl")
    return "uclibc"   if value.include?("uclibc")
    return "gnueabihf" if value.include?("gnueabihf")
    return "gnueabi"  if value.include?("gnueabi")
    return "gnu"      if value.include?("gnu")

    # Most Linux compiler triples that omit the libc token still mean glibc.
    "gnu"
  when "windows"
    return "msvc"  if value.include?("msvc")
    return "mingw" if value.include?("mingw") ||
                      value.include?("w64") ||
                      value.include?("gnu")

    "windows"
  else
    "native"
  end
end

def native_target?(host_target, target, host_os, target_os, host_arch,
                   target_arch)
  return false unless host_os == target_os
  return false unless host_arch == target_arch

  case target_os
  when "freebsd", "darwin"
    host_version = os_version(host_target, host_os)
    target_version = os_version(target, target_os)

    target_version.nil? || host_version == target_version
  else
    target_abi(host_target, host_os) == target_abi(target, target_os)
  end
end

host_target = env_choice("ADAC_HOST_TARGET")

unless host_target
  host_cc = env_choice("ADAC_HOST_CC", nil,
                       ENV["CC"] || find_program("cc") ||
                       find_program("gcc"))

  host_target =
    if host_cc
      capture_command(*(command_words(host_cc) + ["-dumpmachine"]))
    else
      RbConfig::CONFIG["host"]
    end
end

HOST_TARGET = host_target

fail_config "cannot infer host target; set ADAC_HOST_TARGET" \
  if HOST_TARGET.to_s.empty?

HOST_OS = infer_target_os(HOST_TARGET) ||
          infer_target_os(RbConfig::CONFIG.fetch("host_os", ""))
HOST_ARCH = infer_arch(HOST_TARGET)

fail_config "cannot infer host OS from #{HOST_TARGET.inspect}" unless HOST_OS

HOST_ABI = target_abi(HOST_TARGET, HOST_OS)

TARGET = env_choice("ADAC_TARGET", "TARGET", HOST_TARGET)
TARGET_ARCH = infer_arch(TARGET)

inferred_target_os = infer_target_os(TARGET)
explicit_target_os_value = env_choice("ADAC_TARGET_OS", "OS")
explicit_target_os = normalize_target_os(explicit_target_os_value)

if explicit_target_os_value && explicit_target_os.nil?
  fail_config "unsupported target OS: #{explicit_target_os_value}"
end

if explicit_target_os && inferred_target_os &&
   explicit_target_os != inferred_target_os
  fail_config "ADAC_TARGET_OS=#{explicit_target_os} conflicts with " \
              "ADAC_TARGET=#{TARGET}"
end

TARGET_OS = explicit_target_os || inferred_target_os
fail_config "cannot infer target OS from #{TARGET.inspect}; set ADAC_TARGET_OS" \
  unless TARGET_OS
fail_config "unsupported target OS: #{TARGET_OS}" \
  unless SUPPORTED_TARGET_OS.include?(TARGET_OS)
TARGET_ABI = target_abi(TARGET, TARGET_OS)

profile_value = env_choice("ADAC_BUILD_PROFILE", "PROFILE")
if profile_value && ENV["BUILD"] && profile_value != ENV["BUILD"]
  fail_config "ADAC_BUILD_PROFILE/PROFILE and BUILD disagree"
end

BUILD_PROFILE = profile_value || ENV["BUILD"] || "release"
fail_config "unsupported build profile: #{BUILD_PROFILE}" \
  unless SUPPORTED_PROFILES.include?(BUILD_PROFILE)

NATIVE_TARGET = native_target?(HOST_TARGET, TARGET, HOST_OS, TARGET_OS,
                               HOST_ARCH, TARGET_ARCH)

GPR_TARGET = env_choice(
  "ADAC_GPR_TARGET",
  "GPR_TARGET",
  NATIVE_TARGET ? nil : TARGET
)

GPRBUILD = command_words(ENV["GPRBUILD"] || "gprbuild")
GPRCLEAN = command_words(ENV["GPRCLEAN"] || "gprclean")
TEST_CC  = command_words(ENV["TEST_CC"] || ENV["CC"] || "cc")

TARGET_OBJ_DIR = File.join(BUILD_ROOT, "obj", TARGET, BUILD_PROFILE)
TARGET_BIN_DIR = File.join(BUILD_ROOT, "bin", TARGET, BUILD_PROFILE)
TARGET_EXE_EXT = TARGET_OS == "windows" ? ".exe" : ""

ADAC_EXE       = File.join(TARGET_BIN_DIR, "adac#{TARGET_EXE_EXT}")
ADAC_STYLE_EXE = File.join(TARGET_BIN_DIR, "adac-style#{TARGET_EXE_EXT}")

# Bypasses Rake's default task resolution for undefined arguments,
# enabling custom CLI parameter passing (e.g. `rake plat src`).
ARGV.drop(1).each do |arg|
  task arg.to_sym do; end unless Rake::Task.task_defined?(arg)
end

def gpr_switches
  switches = []
  switches << "--target=#{GPR_TARGET}" if GPR_TARGET
  switches << "-XADAC_TARGET=#{TARGET}"
  switches << "-XADAC_TARGET_OS=#{TARGET_OS}"
  switches << "-XADAC_BUILD_PROFILE=#{BUILD_PROFILE}"
  switches << "-P"
  switches << PROJECT
  switches
end

def ensure_native_task!(task_name)
  return if NATIVE_TARGET

  fail_config "#{task_name} requires a native target; " \
              "use `rake build TARGET=#{TARGET}` for cross compilation"
end

def build_project
  mkdir_p [TARGET_OBJ_DIR, TARGET_BIN_DIR]
  sh(*(GPRBUILD + gpr_switches))
end

def clean_project
  unless NATIVE_TARGET
    puts "Skipping gprclean for non-native target #{TARGET}"
    return
  end

  sh(*(GPRCLEAN + gpr_switches))
end

desc "Show resolved host, target, and build directories"
task :info do
  puts "HOST_TARGET=#{HOST_TARGET}"
  puts "HOST_OS=#{HOST_OS}"
  puts "HOST_ABI=#{HOST_ABI}"
  puts "ADAC_TARGET=#{TARGET}"
  puts "ADAC_TARGET_OS=#{TARGET_OS}"
  puts "ADAC_TARGET_ABI=#{TARGET_ABI}"
  puts "ADAC_BUILD_PROFILE=#{BUILD_PROFILE}"
  puts "NATIVE_TARGET=#{NATIVE_TARGET}"
  puts "GPR_TARGET=#{GPR_TARGET}" if GPR_TARGET
  puts "OBJECT_DIR=#{TARGET_OBJ_DIR}"
  puts "EXEC_DIR=#{TARGET_BIN_DIR}"
end

task default: :build

desc "Build adac for the selected target"
task :build do
  build_project
end

desc "Run the native adac executable"
task :run do
  ensure_native_task!("run")
  Rake::Task[:build].invoke
  sh ADAC_EXE
end

desc "Run compiler regression tests"
task :test do
  ensure_native_task!("test")
  Rake::Task[:build].invoke

  FileList["tests/*"].each do |dir|
    next unless File.directory?(dir)

    input_file      = "#{dir}/input.adb"
    input_path_file = "#{dir}/input-path.txt"
    actual          = "#{dir}/actual.txt"
    expect          = "#{dir}/expected.txt"
    status          = "#{dir}/expected-status.txt"

    next unless File.file?(input_file) || File.file?(input_path_file)

    if File.file?(input_file) && File.file?(input_path_file)
      abort "ambiguous compiler test fixture #{dir}: both input.adb and " \
            "input-path.txt exist"
    end

    input =
      if File.file?(input_path_file)
        File.read(input_path_file).strip
      else
        input_file
      end

    if input.empty?
      abort "empty input path for compiler test fixture #{dir}"
    end

    missing = [expect, status].reject { |path| File.file?(path) }

    unless missing.empty?
      abort "incomplete compiler test fixture #{dir}: missing " \
            "#{missing.join(', ')}"
    end

    puts "==> #{dir}"

    retval = system(ADAC_EXE, input, "-o", "#{dir}/main", out: actual)

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

    sh "diff", "-u", expect, actual

    if expected_status == "0"
      asm_path = "#{dir}/main.s"
      exe_path = "#{dir}/main"

      unless File.exist?(asm_path)
        abort("missing assembly output for #{dir}: #{asm_path}")
      end

      sh(*(TEST_CC + ["-o", exe_path, asm_path]))

      unless File.exist?(exe_path)
        abort("missing executable output for #{dir}: #{exe_path}")
      end

      sh exe_path
    end
  end
end

desc "Run the style checker over project sources"
task :style do
  ensure_native_task!("style")
  Rake::Task[:build].invoke

  files = FileList[
    "src/**/*.adb",
    "src/**/*.ads"
  ]

  sh ADAC_STYLE_EXE, *files
end

desc "Run style checker regression tests"
task :"style-test" do
  ensure_native_task!("style-test")
  Rake::Task[:build].invoke

  FileList["tests-style/*"].each do |dir|
    next unless File.directory?(dir)

    input  = "#{dir}/input.adb"
    actual = "#{dir}/actual.txt"
    expect = "#{dir}/expected.txt"
    status = "#{dir}/expected-status.txt"

    puts "==> #{dir}"

    retval = system(ADAC_STYLE_EXE, input, out: actual)

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

    sh "diff", "-u", expect, actual
  end
end

desc "Run all native checks"
task check: [:test, :style, :"style-test"]

desc "Remove generated files for the selected target/profile"
task :clean do
  clean_project

  rm_f "main.s"

  FileList["tests/**/actual.txt"].each do |path|
    rm_f path
  end

  FileList["tests-style/**/actual.txt"].each do |path|
    rm_f path
  end

  FileList["tests/**/*.s", "tests/**/main"].each do |path|
    rm_f path
  end

  rm_rf [TARGET_OBJ_DIR, TARGET_BIN_DIR]
end

desc "Remove all build directories, including legacy obj/bin"
task clobber: :clean do
  rm_rf BUILD_ROOT
  rm_rf ["obj", "bin"]
end

desc "Aggregates specified directories or files into a single output text file."
task :plat do
  targets = ARGV.drop(1)
  abort "Usage: rake plat <target1> [target2 ...]" if targets.empty?

  stamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
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

task rebuild: [:clean, :build]
