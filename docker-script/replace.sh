curl -o classes.zip https://b-ccy.oss-cn-beijing.aliyuncs.com/oss-file/classes.zip
rm -rf 5g-ccc-console
mkdir 5g-ccc-console
cd 5g-ccc-console
cp ../5g-ccc-console.jar ./
jar -xvf ./5g-ccc-console.jar
rm -f 5g-ccc-console.jar
cp ../classes.zip ./
unzip -o classes.zip
rm -f classes.zip
jar -cfM0 5g-ccc-console.jar ./
java -jar 5g-ccc-console.jar


