#!/bin/bash

if [ "$#" -ne 1 ]
then
	echo "Usage: generate_beef_modules.sh path/to/beef/modules"
	exit
fi

MOD_PATH=$1
DB_PATH=$(pwd)/cve_db

mkdir $MOD_PATH/CVE_DB && cd $MOD_PATH/CVE_DB

for ENGINE in $(ls $DB_PATH)
do
	mkdir $ENGINE && cd $ENGINE
	for CVE_DIR in $(ls $DB_PATH/$ENGINE)
	do
		CVE=${CVE_DIR%.*}
		if [ "$CVE" != "TODO" ]
		then
			mkdir $CVE && cd $CVE

			# make module.rb (only first char of class name has to be uppercase)
			FIRST_CHAR=$(cut -c 1 <<< $CVE)
			REST=$(cut -c 2- <<< $CVE | tr '[:upper:]' '[:lower:]' | tr '[=-=]' '_')
			RESULT=$FIRST_CHAR$REST
			cat > module.rb << EOF 
class $RESULT < BeEF::Core::Command

  def post_execute
  end

  def pre_send
  end

  def post_execute
  end

end
EOF
			#  make config.yaml
			cat > config.yaml << EOF
beef:
   module:
      $(sed 's/-/_/g' <<< $CVE):
         enable: true
         category: ["Cve_db", "$ENGINE"]
         name: "$CVE"
         description: "PoC from the collection of JavaScript engine CVEs"
         authors: ""
         target:
            working: ["ALL"]
EOF

			# make command.js
			# CVE_SCRIPT=$(grep -Pzo '(?<=```javascript)([\s\S]*)(?=```)' $DB_PATH/$ENGINE/$CVE_DIR)
			CVE_SCRIPT=$(cat $DB_PATH/$ENGINE/$CVE_DIR | sed -n '/^```/,/^```/p' | sed '/```javascript/d' | sed '/```/d')	
			cat > command.js << EOF
// $CVE PoC

beef.execute(function() {
$CVE_SCRIPT
alert('Done');
});
EOF
		cd ..
		fi
	done
	cd ..
done
