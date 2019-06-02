

# APK
ORIGINAL_APK="/data/app/com.beatgames.beatsaber-1/base.apk"
BACKUP_APK="backup/base_original.apk"
PATCHED_APK="apk/base_patched.apk"

# DLC
DLC_FILES="/sdcard/Android/obb/com.beatgames.beatsaber/."
BACKUP_DLC="backup/DLC/."

# Local files 
LOCAL_FILES="/sdcard/Android/data/com.beatgames.beatsaber/files/."
BACKUP_FILE="backup/files/."

# Custom Songs
CustomSongsZip="CustomSongsZip"
CustomSongsPath="CustomSongs"

# Tools

# Song Converter: https://github.com/lolPants/songe-converter
SONG_CONVERTER="tools/songe-converter-mac.dms" 

# Patcher: https://github.com/trishume/QuestSaberPatch
PATCHER="tools/questsaberpatch/app"

# APK Signer: https://github.com/patrickfav/uber-apk-signer
APK_SIGNER_JAR="tools/uber-apk-signer-1.0.0.jar"

function pause(){
   read -p "$*"
}

# Check existing tools 

echo "Checking Tools ..."
# prepare folder?
mkdir -p "$BACKUP_APK"
mkdir -p "$PATCHED_APK"
mkdir -p "$BACKUP_DLC"
mkdir -p "$BACKUP_FILE"
mkdir -p "$CustomSongsPath"

if [ ! -f "$SONG_CONVERTER" ]; then
	echo "Error: $SONG_CONVERTER is not found."
	exit 1
else	
	echo "Tools: song converter is found!"
fi

if [ ! -f "$PATCHER" ]; then
	echo "Error: $PATCHER is not found."
	exit 1
else	
	echo "Tools: patcher is found!"
fi

if [ ! -f "$APK_SIGNER_JAR" ]; then
	echo "Error: $APK_SIGNER_JAR is not found."
	exit 1
else	
	echo "Tools: apk signer is found!"
fi




echo "Running..."

# ---------
echo "Beginning backup..."
# Backup original apk (one-time)
if [ ! -f "$BACKUP_APK" ]; then
    echo "Backup: APK"
    adb pull "$ORIGINAL_APK" "$BACKUP_APK"
    if [ $? = 1 ]; then 
    	echo "Error: Cannot backup APK file."
    	exit 1
    else 
    	echo "Backup APK file at: $BACKUP_APK"
    fi 
fi

# Update patched apk 
if [ ! -f "$PATCHED_APK" ]; then
	# Prepare patched apk 
	echo "cp $BACKUP_APK $PATCHED_APK"
	cp "$BACKUP_APK" "$PATCHED_APK" 
	if [ $? = 1 ]; then 
    	echo "Error: Cannot prepare patched APK file."
    	exit 1
   	fi
fi 

echo "Backup: DLC"
adb pull "$DLC_FILES" "$BACKUP_DLC"

if [ $? = 1 ]; then 
	echo "Error: Cannot backup DLCs."
	exit 1
fi 

echo "Backup: Local Data"
adb pull  "$LOCAL_FILES" "$BACKUP_FILE"
if [ $? = 1 ]; then 
	echo "Error: Cannot local files."
	exit 1
fi

# ---------
echo "Paparing custom songs..."

# Unzip songs 
echo "unzip -n ${CustomSongsZip}/*.zip -d $CustomSongsPath"
unzip -n "${CustomSongsZip}/*.zip" -d "$CustomSongsPath"

# Convert songs 
echo "./$SONG_CONVERTER -a $CustomSongsPath"
./$SONG_CONVERTER -a "$CustomSongsPath"
if [ $? = 1 ]; then 
	echo "Error: ./$SONG_CONVERTER failed"
	exit 1
fi

# ---------
echo "Patching apk..."
# Patch the current apk 
echo "./$PATCHER $PATCHED_APK $CustomSongsPath"
./$PATCHER "$PATCHED_APK" "$CustomSongsPath"
if [ $? = 1 ]; then 
	echo "Error: Patching failed"
	exit 1
fi

# Sign apk 
echo "Signing apk "
echo java -jar "$APK_SIGNER_JAR" -a "$PATCHED_APK" -o "${PATCHED_APK}_signed"
java -jar "$APK_SIGNER_JAR" -a "$PATCHED_APK" -o "${PATCHED_APK}_signed"
if [ $? = 1 ]; then 
	echo "Error: APK signing failed"
	exit 1
fi

pause 'Press [Enter] key to continue...'

# Install the patched apk 
echo adb install -r ${PATCHED_APK}_signed/*.apk
adb install -r ${PATCHED_APK}_signed/*.apk
if [ $? = 1 ]; then 
	echo "Error: APK installation failed"
	exit 1
fi

# ---------
echo "Update the backup data..." # just in case?
# Push data back 
adb push --sync "$BACKUP_DLC" "$DLC_FILES" 
adb push --sync "$BACKUP_FILE" "$LOCAL_FILES" 

echo "Finish!"
