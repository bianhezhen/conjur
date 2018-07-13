# frozen_string_literal: true

require 'fileutils'
require 'time'

desc "Export the Conjur data necessary to migrate to Enterprise Edition"
task :export, [ "out_dir" ] do |t,args|
  out_dir = args[:out_dir]

  puts "Exporting to '#{args[out_dir]}'..."

  # Make sure output directory exists and we can write to it
  FileUtils.mkpath out_dir
  FileUtils.chmod 0770, out_dir

  # TODO: Setup encryption key
  # e.g. https://github.com/conjurinc/evoke/blob/8d8d06957fd30f5fbb314a92e8d8eb996115c4af/lib/evoke/action/backup.rb#L40-L45

  # Timestamp to name export file
  timestamp = Time.now.strftime("%Y-%m-%dT%H-%M-%SZ")

  with_umask 077 do
    # Dump Conjur database
    puts "  ...Dumping SQL data..."
    dbdump = "#{out_dir}/conjur.db"
    call %(pg_dump -Fc -f \"#{dbdump}\" #{ENV['DATABASE_URL']}) or
      fail 'unable to get database backup'

    # Dump Roles
    puts "  ...Dumping SQL roles..."
    roldump = "#{out_dir}/roles.sql"
    call %(pg_dumpall --roles-only --file=\"#{roldump}\" -d #{ENV['DATABASE_URL']}) or
      fail 'unable to get roles backup'

    #Dump DATA_KEY
    puts "  ...Dumping data key..."
    keydump = "#{out_dir}/conjur.key"
    File.write(keydump, "CONJUR_DATA_KEY=#{ENV['CONJUR_DATA_KEY']}\n")

    archive = "#{out_dir}/#{timestamp}.tar.xz"
    call %(tar JPcf "#{archive}" "#{dbdump}" "#{roldump}" "#{keydump}") or
      fail 'unable to make archive for backup'
  end

  puts "  ...Done!"
end

def with_umask umask, &block
  saved_umask = File.umask umask
  begin
    yield
  ensure
    File.umask saved_umask
  end
end

def call *args
  system(*args).tap do |result|
    warn "command #{Array(args).join(' ')} failed" unless result
  end
end
