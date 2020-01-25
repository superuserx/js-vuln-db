#!/bin/bash

if [ "$#" -ne 2 ]
then
	echo "Usage: generate_beef_modules.sh path/to/beef/modules"
	exit
fi

MOD_PATH=$1

mkdir $MOD_PATH/CVE_PoC && cd $MOD_PATH/CVE_PoC

for ENGINE in $(ls)
do
	mkdir $ENGINE && cd $ENGINE
	for CVE_DIR in $(ls $ENGINE)
	do
		CVE=${CVE_DIR%.*}
		if [ "$CVE" != "TODO" ]
		then
			mkdir $CVE && cd $CVE

			# make module.rb
			cat > module.rb << EOF 
class $(sed 's/-/_/g; s/V/v/g; s/E/e/g;' <<< $CVE) < BeEF::Core::Command

  def post_execute
    content = {}
    content['output'] = @datastore['output'] unless @datastore['output'].nil?
    if content.empty?
      content['fail'] = 'Failed'
    end
    save content
  end

end
EOF
			#  make config.yaml
			cat > config.yaml << EOF
beef:
   module:
      $(sed 's/-/_/g' <<< $CVE):
         enable: true
         category: ["CVE_DB", "$ENGINE"]
         name: "$CVE"
	 description: "PoC from the collection of JavaScript engine CVEs"
         authors: ""
         target:
            working: ["ALL"]
EOF

			# make command.js
			CVE_SCRIPT=$(grep -Pzoq '(?<=```javascript)([\s\S]*)(?=```)' $ENGINE/$CVE_DIR)	
			cat > command.js << EOF
# $CVE PoC

beef.execute(function() {
$CVE_SCRIPT
});
EOF
		cd ..
		fi
	done
	cd ..
done
