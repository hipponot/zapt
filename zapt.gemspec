lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zapt/version'
Gem::Specification.new do |gem|
  basedir = File.dirname(__FILE__)
  gem.name          = %q{zapt}
  gem.authors       = ["Sean Kelly"]
  gem.email         = ["sean.kelly@wootlearning.com"]
  gem.description   = %q{generic kudu module description}
  gem.summary       = %q{generic kudu module summary}
  gem.homepage      = %q{http://wootlearning.com}  
  gem.files         = Dir.glob("lib/**/*").select {|f| f !=  "sha1"} +
                      Dir.glob("bin/**/*") +
                      Dir.glob("config/**/*") +
                      Dir.glob("ext/**/*.{cpp,h,rb,c}") +
                      Dir.glob("kudu.yaml")
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.license       = 'MIT'
  gem.require_paths = ["lib"]

  begin
    kudu_file = File.join(basedir,'kudu.yaml')
    lock_file = File.join(basedir,'kudu.lock.yaml')
    file = File.exist?(lock_file) ? lock_file : kudu_file
    text = IO.read(file)
    kudu = YAML::load(text)
    kudu[:dependencies].select {|e| e[:group] != 'developer' }.each do |dep|
      name = dep[:namespace].nil? ? dep[:name] : dep[:namespace] + "_" + dep[:name]
      gem.add_dependency name, dep[:version] 
    end                                                   
    ver_file = File.join(basedir,'VERSION')
    gem.version = IO.read(ver_file)
    gem.files << File.basename(ver_file)
  rescue Exception=>e
    abort("Error parsing kudu.yaml #{e}")
  end

end
