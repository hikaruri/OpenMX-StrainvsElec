#!/bin/bash

start_time=`date +%s`

#
# Set the parameter
#
  ElecStart=0.0
  ElecUnit=0.5
  ElecEnd=30.0
  
  LatCStart=4.31
  LatCUnit=0.02
  LatCEnd=4.77

  SystemName="Bi"
  PI=3.141592653589793
  caxis=20.0
  OMXPATH=~/openmx3.8/source

  OutputFile="$SystemName.ElecvsLC"
 # echo "#Lattice Constant Electric field Z2 Total Energy Bandgap" >> $OutputFile

   upspin=7.5
   downspin=7.5
   Atom1="Bi"
   Atom2="Bi"
#
# loop for Electric field
#
   for Elec in `seq $ElecStart $ElecUnit $ElecEnd`
   do
#
#
# loop for Lattice Constant
#
   for LatC in `seq $LatCStart $LatCUnit $LatCEnd`
   do

      FileName="$SystemName"E"$Elec"LC"$LatC"
      cp $SystemName.dat $FileName.dat
      printf "\n" >> $FileName.dat
      echo "System.Name  $FileName" >> $FileName.dat
      #
      # Write Unit Cell Vector
      #
      echo "<Atoms.UnitVectors" >> $FileName.dat
      printf "%f %f %f\n"  0.000000 $LatC 0.000000 >> $FileName.dat
      Csin=`echo "scale=7; $LatC*s($PI/3.0)" | bc -l`
      Ccos=`echo "scale=7; $LatC*c($PI/3.0)" | bc -l`
      printf "%f %f %f\n" $Csin $Ccos 0.000000 >> $FileName.dat
      printf "%f %f %f\n" 0.000000 0.000000 $caxis >> $FileName.dat
      echo "Atoms.UnitVectors>" >> $FileName.dat
      
      #
      # Write Atom Coordinates
      #

      if [ $Elec = 0.0 ]; then
        echo "Atoms.SpeciesAndCoordinates.Unit   FRAC" >> $FileName.dat
        echo "MD.Type    Opt" >> $FileName.dat
        echo "<Atoms.SpeciesAndCoordinates" >> $FileName.dat
        printf "%d %s %f %f %f %f %f\n" 1 $Atom1 0.00000000 0.00000000 0.50000000 $upspin $downspin >> $FileName.dat
        printf "%d %s %f %f %f %f %f\n" 2 $Atom2 0.66666667 0.66666667 0.60000000 $upspin $downspin >> $FileName.dat
        echo "Atoms.SpeciesAndCoordinates>" >> $FileName.dat
      else
        echo "Atoms.SpeciesAndCoordinates.Unit   Ang" >> $FileName.dat
        echo "MD.Type    Nomd" >> $FileName.dat
        echo "<Atoms.SpeciesAndCoordinates" >> $FileName.dat
        tail -n  2 "$SystemName"E0.0""LC"$LatC".md2 >> $FileName.dat
        echo "Atoms.SpeciesAndCoordinates>" >> $FileName.dat
      fi
     
      #
      # Write Electric Field strength
      #
      printf "%s %f %f %f\n" scf.Electric.field 0.0 0.0 $Elec >> $FileName.dat
      #
      # SCF calculation and Z2
      #
      $OMXPATH/openmx $FileName.dat > $FileName.std
      $OMXPATH/Z2FH $FileName.scfout < Z2FH.in > Z2$FileName.out
      rm -r "$FileName"_rst/
      #
      # Write total energy
      #
      grep Utot $FileName.std > Utot.txt
      cat Utot.txt | tr -cd '.-0123456789\n' > Utot1.txt
      TotalEnergy=`awk 'NR==1' Utot1.txt`
      rm Utot*.txt
      #
      # Write Bandgap Energy
      #
      $OMXPATH/bandgnu13 $FileName.Band > bandgnu.out
      Bandgap=`$OMXPATH/bandgap $FileName.BANDDAT1`
      rm bandgnu.out
      #
      # Fukui-Hatsugai Z2
      #
      Z2number=`cat Z2.dat`
      rm Z2.dat
      #
      # Write output for topological phase diagram
      #
      printf "%f %f %f %f %f\n" $LatC $Elec $Z2number $TotalEnergy $Bandgap >> $OutputFile
    done
      printf "\n" >> $OutputFile
done

end_time=`date +%s`

time=$((end_time - start_time))
hour=`echo "$time/3600"| bc`
minute=`echo "($time-3600*$hour)/60"| bc`
second=`echo "($time-3600*$hour-60*$minute)"| bc`
echo "Computational Time = $hour:$minute:$second" > Time.dat
