BEGIN { printf "START" }
/^[[:blank:][:cntrl:]]*$/ { printf "E"; next }
/^# / { printf "1"; next}
/^## / { printf "2"; next}
/^### / { printf "3"; next}
/^#### / { printf "4"; next}
/^##### / { printf "5"; next}
/^###### / { printf "6"; next}
/^> / { printf "B"; next}
/^</ { printf "T"; next}
{ printf "O" }
END { printf "END"}
