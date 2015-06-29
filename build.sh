
BUILD_TARGET="release"
PROJECT_NAME="${PWD##*/}"

ANDROID_VERSION=android-21

CLEAN="false"
GPGS="true"
MULTIDEX="true"
LAZY="false"


usage() { echo "Usage: -c clean -t target -a android_version -g no gpgs -m no mutlidex"; exit 1; }



buildGPGS(){

	echo "----------------Build custom GPGS----------------"

	#remove useless muneris google play service
	rm -r ../google-play-services

	#copy libs
	ditto ../../Assets/plugins/Android/google-play-services_lib ../google-play-services_lib
	ditto ../../Assets/plugins/Android/MainLibProj ../MainLibProj

	#remove .meta
	find .. -name "*.meta" -type f -delete

	#update projects
	android update project --path ../google-play-services_lib --target $ANDROID_VERSION
	android update project --path ../MainLibProj --target $ANDROID_VERSION

	#update native project project.properties
	cp ~/util/nativeProject.properties ../MainLibProj/project.properties


	#create dummy src folder for MainLibProj
	mkdir ../MainLibProj/src

}


prepareMultidex(){
	echo "----------------Prepare Multidex----------------"


	cp ~/util/pathtool.jar ./pathtool.jar
	cp ~/util/custom_rules.xml ./custom_rules.xml
	cp ~/util/MunerisUnityPlayerProxyActivity.java ./src/muneris/unity/androidbridge/MunerisUnityPlayerProxyActivity.java

}

linking(){

	echo "----------------Linking----------------"
	cp ~/util/project.properties project.properties

	cd ..

	i=1
	for FILE in *
	do
		
		if [ "$FILE" != "$PROJECT_NAME" ]; then
	
			
			echo android.library.reference.$i=../$FILE >> "$PROJECT_NAME"/project.properties
			i=$((i+1))
		fi
		
	done

	cd "$PROJECT_NAME"
}



while getopts ":t:a:cgml" o; do
    case "${o}" in
        c)
            CLEAN="true"
            ;;
        t)
            BUILD_TARGET="$OPTARG"
            ;;
        a)
            ANDROID_VERSION=$OPTARG
            ;;
        g)
            GPGS="false"
            ;;
        m)
            MULTIDEX="false"
            ;;
	l)
            LAZY="true"
            ;;
        \?)
            usage
            ;;
    esac
done


   

#lazy build - save time by using pre-dex jars
if [ "$LAZY" == "true" ]; then
    echo "----------------LAZY BUILD----------------"
    ditto ~/util/jar libs/
    ditto ~/util/dexedLibs bin/dexedLibs
    ditto ~/util/libs.apk bin/libs.apk
fi


#clean
if [ "$CLEAN" == "true" ]; then
    echo "----------------Clean----------------"
    ant clean

fi


if [ "$MULTIDEX" == "true" ]; then
	prepareMultidex
else
	echo "NO multidex!!!!!!!!"
	cp ~/util/custom_rulesNoMultiDex.xml custom_rules.xml
	cp ~/util/MunerisUnityPlayerProxyActivityNormal.java ./src/muneris/unity/androidbridge/MunerisUnityPlayerProxyActivity.java
	#remove useless shit directly if no multidex
	cp ~/util/useless.txt useless.txt
	cd libs
	cat ../useless.txt | xargs rm
	cd ..
fi


if [ "$GPGS" == "true" ]; then
    buildGPGS
else
    echo "NO GPGS!!!!!!!!"
fi


linking


#copy keystore
cp ~/util/animoca-release-key-1.keystore animoca-release-key-1.keystore


echo "----------------Build----------------"

ant $BUILD_TARGET -Dkey.store=animoca-release-key-1.keystore -Dkey.alias=animoca -Dkey.store.password=password -Dkey.alias.password=password

adb install -r bin/"$PROJECT_NAME"-"$BUILD_TARGET".apk