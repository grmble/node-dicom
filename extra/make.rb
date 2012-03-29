#! /usr/bin/env ruby

require 'rexml/document'


doc = REXML::Document.new File.new "dictionary.xml"
print "export.TAG_DICT = {"
doc.elements.each('dictionary/element') { 
	|e| 
	text = <<EOF
'#{e.attributes['tag']}': {'vr': '#{e.attributes['vr']}', 'vm': '#{e.attributes['vm']}', 'name': '#{e.attributes['keyword']}'},
EOF
	print text
}
print "};"

doc = REXML::Document.new File.new "uids.xml"
print "export.UID_DICT = {"
doc.elements.each('uids/uid') { 
	|e| 
	typ = e.attributes['type'];
	typ.gsub!(/ /, '')
	text = <<EOF
'#{e.attributes['uid']}': {'type': '#{typ}', 'name': '#{e.attributes['keyword']}'},
EOF
	print text
}
print "};"

