{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit bclabelcontour_pkg;

{$warn 5023 off : no warning about unused units}
interface

uses
  BCLabelContour, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('BCLabelContour', @BCLabelContour.Register);
end;

initialization
  RegisterPackage('bclabelcontour_pkg', @Register);
end.
