function Select-VMs {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
        
    # Initialise form objects
    $form = New-Object System.Windows.Forms.Form
    $label = New-Object System.Windows.Forms.Label
    $button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button
    $selectionBox = New-Object System.Windows.Forms.CheckedListBox 
    $loadingLabel = New-Object System.Windows.Forms.Label
    $onlyOffCheckBox = New-Object System.Windows.Forms.CheckBox
    $checkUncheckCheckBox = New-Object System.Windows.Forms.CheckBox
    $initialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    $global:selectionBoxIndex = -1

    # saveButton eventHandler
    $handler_saveButton_Click = {
        $runningVMs = $selectionBox.CheckedItems.Where({ $_.State -ne "Off" })

        if ($runningVMs) {
            $warningSelection = [System.Windows.Forms.Messagebox]::Show('Some of the chosen VMs are still running, do you want to continue? These VMs will be turned off.', 'Are you sure?', 'YesNo', 'Warning')
        
            if ($warningSelection -eq 'No') {
                return
            }
        }

        $global:SelectedVMs = $selectionBox.CheckedItems

        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }

    # cancelButton eventHandler
    $handler_cancelButton_Click = {
        $form.Close()
    }

    $selectionBox_SelectedIndexChanged = {
        $global:selectionBoxIndex = $selectionBox.SelectedIndex
    }

    $selectionBox_MouseDown = {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            if ([System.Windows.Forms.Control]::ModifierKeys -eq [System.Windows.Forms.Keys]::Shift) {
                if ($global:selectionBoxIndex -ne -1) {
                    $topIndex = $global:selectionBoxIndex

                    if ($selectionBox.SelectedIndex -gt $topIndex) {
                        for (($i = ($topIndex)); $i -le $selectionBox.SelectedIndex; $i++){
                            $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
                        }
                    }
                    elseif ($topIndex -gt $selectionBox.SelectedIndex) {
                        for (($i = ($selectionBox.SelectedIndex)); $i -le $topIndex; $i++){
                            $selectionBox.SetItemChecked($i, $selectionBox.GetItemChecked($topIndex))
                        }
                    }
                }
            }
            elseif ($global:selectionBoxIndex -ne $selectionBox.SelectedIndex) {
                $selectionBox.SetItemChecked($selectionBox.SelectedIndex, -not $selectionBox.GetItemChecked($selectionBox.SelectedIndex))
            }
        }
    }

    $check_All = {
        for (($i = 0); $i -lt $selectionBox.Items.Count; $i++){
            $selectionBox.SetItemChecked($i, $checkUncheckCheckBox.Checked)
        }
    }

    $load_VMs = {
        # Correct the initial state of the form to prevent the .Net maximized form issue
        $form.WindowState = $initialFormWindowState

        # Reset state to default before loading VMs again
        $global:selectionBoxIndex = -1
        $checkUncheckCheckBox.Checked = $False

        # Show loading indicator
        $loadingLabel.Visible = $true
        $form.Refresh()

        # Clear selectionBox before adding any new items
        $selectionBox.Items.Clear()

        $VMList = Get-VM

        # Filter only off
        if ($onlyOffCheckBox.Checked) {
            $VMList = $VMList | Where-Object { $_.State -eq "Off" }
        }

        # Go through VM list and add items one by one to the selectionBox
        Foreach ($vm in $VMList) { 
            # Add the VM to the selectionBox and set it's checked status
            $selectionBox.Items.Add($vm, $false) | Out-Null
        }
        
        # Hide loading indicator
        $loadingLabel.Visible = $False

        # Sort selectionBox alphabetically
        $selectionBox.Sorted = $True
    }

    $form.Text = "VM Selection"
    $form.Name = "vmSelectionForm"
    $form.DataBindings.DefaultDataSourceUpdateMode = 0
    $form.ClientSize = New-Object System.Drawing.Size(600,502)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $False

    $button1.TabIndex = 4
    $button1.Name = "saveButton"
    $button1.UseVisualStyleBackColor = $True
    $button1.Text = "Confirm"
    $button1.Location = New-Object System.Drawing.Point(27,472)
    $button1.Size = New-Object System.Drawing.Size(75,23)
    $button1.DataBindings.DefaultDataSourceUpdateMode = 0
    $button1.add_Click($handler_saveButton_Click)

    $form.Controls.Add($button1)

    $button2.TabIndex = 5
    $button2.Name = "cancelButton"
    $button2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $button2.UseVisualStyleBackColor = $True
    $button2.Text = "Cancel"
    $button2.Location = New-Object System.Drawing.Point(129,472)
    $button2.Size = New-Object System.Drawing.Size(75,23)
    $button2.DataBindings.DefaultDataSourceUpdateMode = 0
    $button2.add_Click($handler_cancelButton_Click)

    $form.Controls.Add($button2)

    $label.Location = New-Object System.Drawing.Point(13,5)
    $label.Size = New-Object System.Drawing.Size(400,14)
    $Label.Font = 'Microsoft Sans Serif,8'
    $label.Text = 'Check VMs that you wish to update, uncheck VMs that you wish to ignore'

    $form.Controls.Add($label)

    $loadingLabel.Location = New-Object System.Drawing.Point(16,46)
    $loadingLabel.Size = New-Object System.Drawing.Size(300,418)
    $loadingLabel.Text = 'Loading VMs...'
    $loadingLabel.BackColor = "White"
    $loadingLabel.Visible = $false

    $form.Controls.Add($loadingLabel)

    $onlyOffCheckBox.TabIndex = 6
    $onlyOffCheckBox.Location = New-Object System.Drawing.Point(230,474)
    $onlyOffCheckBox.Size = New-Object System.Drawing.Size(250,20)
    $onlyOffCheckBox.Text = 'Only show turned off VMs'
    $onlyOffCheckBox.add_CheckedChanged($load_VMs)

    $form.Controls.Add($onlyOffCheckBox)

    $checkUncheckCheckBox.TabIndex = 7
    $checkUncheckCheckBox.Location = New-Object System.Drawing.Point(16,22)
    $checkUncheckCheckBox.Size = New-Object System.Drawing.Size(150,20)
    $checkUncheckCheckBox.Text = 'Check/Uncheck all'
    $checkUncheckCheckBox.add_CheckedChanged($check_All)

    $form.Controls.Add($checkUncheckCheckBox)

    $selectionBox.FormattingEnabled = $True
    $selectionBox.DataBindings.DefaultDataSourceUpdateMode = 0
    $selectionBox.Name = "selectionBox"
    $selectionBox.Location = New-Object System.Drawing.Point(13,43)
    $selectionBox.Size = New-Object System.Drawing.Size(574,424)
    $selectionBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $selectionBox.TabIndex = 3
    $selectionBox.add_SelectedIndexChanged($selectionBox_SelectedIndexChanged)
    $selectionBox.add_Click($selectionBox_MouseDown)

    $form.Controls.Add($selectionBox)

    # Save the initial state of the form
    $initialFormWindowState = $form.WindowState

    # Load VMs into selectionBox
    $form.add_Load($load_VMs)

    # Focus selectionBox when form opens
    $form.Add_Shown({$form.Activate(); $selectionBox.Focus()})

    # Show the Form
    return $form.ShowDialog()
}