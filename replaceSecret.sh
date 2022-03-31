TARGETPCH=Example/Whiteboard/Whiteboard-Prefix.pch
TESTPCH=Example/Tests/Tests-Prefix.pch

# project comment
comment='\/\/'#'define'
to=''#'define'
sed -i "" "s/$comment/$to/g" $TARGETPCH

# roomuuid
uuid='<'#'Room UUID'#'>'
sed -i "" "s/$uuid/$1/g" $TARGETPCH
sed -i "" "s/$uuid/$1/g" $TESTPCH
# roomToken
roomToken='<\'#'Room Token\'#'>'
sed -i "" "s/$roomToken/$2/g" $TARGETPCH
sed -i "" "s/$roomToken/$2/g" $TESTPCH
# appidentifier
appidentifier='<'#'@App identifier'#'>'
sed -i "" "s/$appidentifier/$3/g" $TARGETPCH
sed -i "" "s/$appidentifier/$3/g" $TESTPCH
# sdktoken
sdkToken='<'#'@sdk Token'#'>'
sed -i "" "s/$sdkToken/$4/g" $TARGETPCH
sed -i "" "s/$sdkToken/$4/g" $TESTPCH
# replayuuid
replayuuid='<'#'Replay UUID'#'>'
sed -i "" "s/$replayuuid/$5/g" $TESTPCH
# replayToken
replayToken='<'#'Replay Token'#'>'
sed -i "" "s/$replayToken/$6/g" $TESTPCH