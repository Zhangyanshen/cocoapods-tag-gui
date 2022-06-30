# -*- encoding: utf-8 -*-
# stub: cocoapods-tag 0.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "cocoapods-tag".freeze
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jensen".freeze]
  s.date = "2022-06-14"
  s.description = "\u65B9\u4FBF\u5730\u5E2E\u52A9pod\u5E93\u6253tag\u7684CocoaPods\u63D2\u4EF6".freeze
  s.email = ["zys2@meitu.com".freeze]
  s.homepage = "https://github.com/Zhangyanshen/cocoapods-tag.git".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "\u65B9\u4FBF\u5730\u5E2E\u52A9pod\u5E93\u6253tag\u7684CocoaPods\u63D2\u4EF6\uFF0C\u53EF\u4EE5\u6821\u9A8Cpodspec\u7684\u5408\u6CD5\u6027".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<cocoapods>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<cocoapods>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
