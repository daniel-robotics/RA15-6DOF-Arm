if (( $# == 1 ))
then
  COM=$1
else
  COM=usb
fi
echo "Executing NeXTTool to upload Math_Test_OSEK.rxe to device: COM=$COM ..."
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -download=Math_Test_OSEK.rxe
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -listfiles=Math_Test_OSEK.rxe
echo NeXTTool is terminated.
