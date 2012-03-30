#! /usr/bin/env ruby

require 'rexml/document'


tag_js = File.new("tag.x", "w")
doc = REXML::Document.new File.new "dictionary.xml"
tag_js.write "var TAG_DICT = {\n"
doc.elements.each('dictionary/element') { 
	|e| 
	text = <<EOF
'#{e.attributes['tag']}': {'vr': '#{e.attributes['vr']}', 'vm': '#{e.attributes['vm']}', 'name': '#{e.attributes['keyword']}'},
EOF
	tag_js.write text
}
tag_js.write "};"

uid_js = File.new("uid.x", "w")
doc = REXML::Document.new File.new "uids.xml"
uid_js.write("var UID_DICT = {\n");
doc.elements.each('uids/uid') { 
	|e| 
	typ = e.attributes['type'];
	typ.gsub!(/ /, '')
	text = <<EOF
'#{e.attributes['uid']}': {'type': '#{typ}', 'name': '#{e.attributes['keyword']}'},
EOF
	uid_js.write(text);
}
uid_js.write("};")

