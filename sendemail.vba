Sub Send_Row_Or_Rows_2()
'For Tips see: http://www.rondebruin.nl/win/winmail/Outlook/tips.htm
'Don't forget to copy the function RangetoHTML in the module.
'Working in Excel 2000-2016
    Dim OutApp As Object
    Dim OutMail As Object
    Dim rng As Range
    Dim Ash As Worksheet
    Dim Cws As Worksheet
    Dim Rcount As Long
    Dim Rnum As Long
    Dim FilterRange As Range
    Dim FieldNum As Integer
    Dim StrBody As String
    Dim StrFooter As String
    
    On Error GoTo cleanup
    Set OutApp = CreateObject("Outlook.Application")
    Set OutAccount = OutApp.Session.Accounts.Item(2)

    With Application
        .EnableEvents = False
        .ScreenUpdating = False
    End With

    'Set filter sheet, you can also use Sheets("MySheet")
    Set Ash = ActiveSheet

    'Set filter range and filter column (column with e-mail addresses)
    Set FilterRange = Ash.Range("A1:H" & Ash.Rows.Count)
    FieldNum = 8    'Filter column = B because the filter range start in column A

    'Add a worksheet for the unique list and copy the unique list in A1
    Set Cws = Worksheets.Add
    FilterRange.Columns(FieldNum).AdvancedFilter _
            Action:=xlFilterCopy, _
            CopyToRange:=Cws.Range("A1"), _
            CriteriaRange:="", Unique:=True

    'Count of the unique values + the header cell
    Rcount = Application.WorksheetFunction.CountA(Cws.Columns(1))

    'If there are unique values start the loop
    If Rcount >= 2 Then
        For Rnum = 2 To Rcount

            'Filter the FilterRange on the FieldNum column
            FilterRange.AutoFilter Field:=FieldNum, _
                                   Criteria1:=Cws.Cells(Rnum, 1).Value

            'If the unique value is a mail addres create a mail
            If Cws.Cells(Rnum, 1).Value Like "?*@?*.?*" Then

                With Ash.AutoFilter.Range
                    On Error Resume Next
                  'Set rng = .SpecialCells(xlCellTypeVisible)
                 Set rng = Intersect(.SpecialCells(xlCellTypeVisible), _
                        Union(.Columns(1), .Columns(2), .Columns(3), .Columns(4), .Columns(5), .Columns(6), .Columns(7)))

                    On Error GoTo 0
                End With

                Set OutMail = OutApp.CreateItem(0)
                
                StrBody = "Dear User," & "<br>" & _
              "Please find the below attendance(In/Out-Time) for your team including all reportees." & "<br>" & _
              "Please let us know in case the list does not contain any of your team members" & "<br>"
              

                StrFooter = "Thank You" & "<br>" & _
                    "This is an Auto Generated Email" & "<br>"
    
                On Error Resume Next
                With OutMail
                
                    .Importance = 1
                    Set .SendUsingAccount = OutAccount
                    
                    .to = Cws.Cells(Rnum, 1).Value
                    .Subject = "Attendance(In/Out-Time) Report for your team"
                    .HTMLBody = StrBody & RangetoHTML(rng) & "<br>" & StrFooter
                    .Send
                End With
                On Error GoTo 0

                Set OutMail = Nothing
            End If

            'Close AutoFilter
            Ash.AutoFilterMode = False

        Next Rnum
    End If

cleanup:
    Set OutApp = Nothing
    Application.DisplayAlerts = False
    Cws.Delete
    Application.DisplayAlerts = True

    With Application
        .EnableEvents = True
        .ScreenUpdating = True
    End With
End Sub

Function RangetoHTML(rng As Range)
' Changed by Ron de Bruin 28-Oct-2006
' Working in Office 2000-2016
    Dim fso As Object
    Dim ts As Object
    Dim TempFile As String
    Dim TempWB As Workbook

    TempFile = Environ$("temp") & "/" & Format(Now, "dd-mm-yy h-mm-ss") & ".htm"

    'Copy the range and create a new workbook to past the data in
    rng.Copy
    Set TempWB = Workbooks.Add(1)
    With TempWB.Sheets(1)
        .Cells(1).PasteSpecial Paste:=8
        .Cells(1).PasteSpecial xlPasteValues, , False, False
        .Cells(1).PasteSpecial xlPasteFormats, , False, False
        .Cells(1).Select
        Application.CutCopyMode = False
        On Error Resume Next
        .DrawingObjects.Visible = True
        .DrawingObjects.Delete
        On Error GoTo 0
    End With

    'Publish the sheet to a htm file
    With TempWB.PublishObjects.Add( _
         SourceType:=xlSourceRange, _
         Filename:=TempFile, _
         Sheet:=TempWB.Sheets(1).Name, _
         Source:=TempWB.Sheets(1).UsedRange.Address, _
         HtmlType:=xlHtmlStatic)
        .Publish (True)
    End With

    'Read all data from the htm file into RangetoHTML
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.GetFile(TempFile).OpenAsTextStream(1, -2)
    RangetoHTML = ts.ReadAll
    ts.Close
    RangetoHTML = Replace(RangetoHTML, "align=center x:publishsource=", _
                          "align=left x:publishsource=")

    'Close TempWB
    TempWB.Close savechanges:=False

    'Delete the htm file we used in this function
    Kill TempFile
    Set ts = Nothing
    Set fso = Nothing
    Set TempWB = Nothing
End Function
