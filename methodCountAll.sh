for FILE in *
	do
		if [[ $FILE == *"jar"* ]]
		then

			echo $FILE" "$(methodCount.sh $FILE)
		fi
	done
