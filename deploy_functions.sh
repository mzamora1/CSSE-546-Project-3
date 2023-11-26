rm -rf "./functions.yml"
cp -r "$FUNCTIONS_SOURCE/functions.yml" ./functions.yml
rm -rf "./face_recognition"
cp -r "$FUNCTIONS_SOURCE/face_recognition" ./face_recognition
faas up -f functions.yml

# docker logout 