module TemporaryDirectory
  def self.included(mod)
    mod.before do
      remove_temporary_directory
      create_temporary_directory
      enter_temporary_directory
    end

    mod.after do
      leave_temporary_directory
      remove_temporary_directory
    end
  end

  def temporary_directory
    "#{ROOT}/tmp"
  end

  #
  # Write +content+ to +path+ under the temporary directory.
  #
  # The parent directory is created if necessary.
  #
  def write_file(path, content=path)
    path = File.join(temporary_directory, path)
    FileUtils.mkdir_p File.dirname(path)
    open(path, 'w'){|f| f.print content}
  end

  private  # ---------------------------------------------------------

  def create_temporary_directory
    FileUtils.mkdir_p temporary_directory
  end

  def remove_temporary_directory
    FileUtils.rm_rf temporary_directory
  end

  def enter_temporary_directory
    @original_pwd = Dir.pwd
    Dir.chdir temporary_directory
  end

  def leave_temporary_directory
    Dir.chdir @original_pwd
  end
end
