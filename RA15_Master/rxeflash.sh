if (( $# == 1 ))
then
  COM=$1
else
  COM=usb
fi
echo "Executing NeXTTool to upload RA15.rxe to device: COM=$COM ..."
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -download=RA15.rxe
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -listfiles=RA15.rxe
echo NeXTTool is terminated.
