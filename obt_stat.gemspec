# -*- coding: utf-8 -*-
require 'rubygems'

SPEC = Gem::Specification.new do |s|
  s.name = "OBT+Stat"
  s.version = "0.9.3"
  s.author = "André Lynum"
  s.email = "andrely@ifi.uio.no"
  s.platform = Gem::Platform::RUBY
  s.summary = "Statistical disambiguator for the Oslo-Bergen Tagger."
  candidates = Dir.glob("{bin,docs,lib,hunpos,models}/**/*")
  s.files = candidates.delete_if do |item|
    item.include?("rdoc")
  end
  
  s.bindir = "bin"
  s.executables << "run_obt_stat.rb"
  
  s.require_path = "lib"
  # s.require = "obt_stat"
  s.has_rdoc = false
  s.extra_rdoc_files = ["LICENCE.txt", "gpl.txt"]
end
