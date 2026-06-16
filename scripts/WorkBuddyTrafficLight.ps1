param(
    [switch]$Probe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "StatusEngine.ps1")

if ($Probe) {
    Get-WorkBuddyTrafficState | ConvertTo-Json -Compress
    exit 0
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$createdNew = $false
$mutex = [System.Threading.Mutex]::new($true, "Local\WorkBuddyTrafficLight", [ref]$createdNew)
if (-not $createdNew) {
    exit 0
}

$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="WorkBuddy Traffic Light"
    Width="126"
    Height="326"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    ShowInTaskbar="False"
    Topmost="True"
    ResizeMode="NoResize">
    <Border
        x:Name="Housing"
        Margin="8"
        Padding="12"
        CornerRadius="22"
        Background="#EE20252B"
        BorderBrush="#553A424A"
        BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="78"/>
                <RowDefinition Height="78"/>
                <RowDefinition Height="78"/>
                <RowDefinition Height="34"/>
            </Grid.RowDefinitions>
            <Ellipse x:Name="RedLamp" Grid.Row="0" Width="62" Height="62" Fill="#39191D" Stroke="#111418" StrokeThickness="5"/>
            <Ellipse x:Name="YellowLamp" Grid.Row="1" Width="62" Height="62" Fill="#3B311C" Stroke="#111418" StrokeThickness="5"/>
            <Ellipse x:Name="GreenLamp" Grid.Row="2" Width="62" Height="62" Fill="#183323" Stroke="#111418" StrokeThickness="5"/>
            <TextBlock
                x:Name="StatusText"
                Grid.Row="3"
                HorizontalAlignment="Center"
                VerticalAlignment="Center"
                Foreground="#E9EEF2"
                FontFamily="Microsoft YaHei UI"
                FontSize="11"
                FontWeight="SemiBold"
                Text="Connecting"/>
        </Grid>
    </Border>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$redLamp = $window.FindName("RedLamp")
$yellowLamp = $window.FindName("YellowLamp")
$greenLamp = $window.FindName("GreenLamp")
$statusText = $window.FindName("StatusText")

$screen = [System.Windows.SystemParameters]::WorkArea
$window.Left = $screen.Right - $window.Width - 24
$window.Top = $screen.Top + 72

$offRed = [Windows.Media.BrushConverter]::new().ConvertFromString("#39191D")
$offYellow = [Windows.Media.BrushConverter]::new().ConvertFromString("#3B311C")
$offGreen = [Windows.Media.BrushConverter]::new().ConvertFromString("#183323")
$onRed = [Windows.Media.BrushConverter]::new().ConvertFromString("#EF4454")
$onYellow = [Windows.Media.BrushConverter]::new().ConvertFromString("#F5B82E")
$onGreen = [Windows.Media.BrushConverter]::new().ConvertFromString("#32D583")

$script:currentState = ""
$script:blinkOn = $true

function Set-LampState {
    param(
        [Parameter(Mandatory)]
        [string]$State,

        [Parameter(Mandatory)]
        [string]$Label
    )

    $redLamp.Fill = $offRed
    $yellowLamp.Fill = $offYellow
    $greenLamp.Fill = $offGreen
    $redLamp.Effect = $null
    $yellowLamp.Effect = $null
    $greenLamp.Effect = $null

    $glow = [Windows.Media.Effects.DropShadowEffect]::new()
    $glow.BlurRadius = 26
    $glow.ShadowDepth = 0
    $glow.Opacity = 0.9

    switch ($State) {
        "working" {
            $yellowLamp.Fill = $onYellow
            $glow.Color = [Windows.Media.ColorConverter]::ConvertFromString("#F5B82E")
            $yellowLamp.Effect = $glow
        }
        "approval" {
            if ($script:blinkOn) {
                $yellowLamp.Fill = $onYellow
                $glow.Color = [Windows.Media.ColorConverter]::ConvertFromString("#FFF0A5")
                $yellowLamp.Effect = $glow
            }
        }
        "complete" {
            $greenLamp.Fill = $onGreen
            $glow.Color = [Windows.Media.ColorConverter]::ConvertFromString("#32D583")
            $greenLamp.Effect = $glow
        }
        default {
            $redLamp.Fill = $onRed
            $glow.Color = [Windows.Media.ColorConverter]::ConvertFromString("#EF4454")
            $redLamp.Effect = $glow
        }
    }

    $statusText.Text = $Label
    $window.ToolTip = "WorkBuddy Traffic Light`n$Label`nDrag to move; right-click to exit"
}

$window.Add_MouseLeftButtonDown({
    try {
        $window.DragMove()
    }
    catch {
        # DragMove can throw when the mouse is released quickly.
    }
})

$menu = [System.Windows.Controls.ContextMenu]::new()
$topmostItem = [System.Windows.Controls.MenuItem]::new()
$topmostItem.Header = "Always on top"
$topmostItem.IsCheckable = $true
$topmostItem.IsChecked = $true
$topmostItem.Add_Click({
    $window.Topmost = $topmostItem.IsChecked
})

$exitItem = [System.Windows.Controls.MenuItem]::new()
$exitItem.Header = "Exit"
$exitItem.Add_Click({
    $window.Close()
})

[void]$menu.Items.Add($topmostItem)
[void]$menu.Items.Add([System.Windows.Controls.Separator]::new())
[void]$menu.Items.Add($exitItem)
$window.ContextMenu = $menu

$statusTimer = [Windows.Threading.DispatcherTimer]::new()
$statusTimer.Interval = [TimeSpan]::FromMilliseconds(800)
$statusTimer.Add_Tick({
    try {
        $state = Get-WorkBuddyTrafficState
        $script:currentState = $state.State
        Set-LampState -State $state.State -Label $state.Label
    }
    catch {
        $script:currentState = "error"
        Set-LampState -State "error" -Label "Status read failed"
    }
})

$blinkTimer = [Windows.Threading.DispatcherTimer]::new()
$blinkTimer.Interval = [TimeSpan]::FromMilliseconds(520)
$blinkTimer.Add_Tick({
    $script:blinkOn = -not $script:blinkOn
    if ($script:currentState -eq "approval") {
        Set-LampState -State "approval" -Label "Approval needed"
    }
})

$window.Add_Closed({
    $statusTimer.Stop()
    $blinkTimer.Stop()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
})

Set-LampState -State "offline" -Label "Connecting"
$statusTimer.Start()
$blinkTimer.Start()
[void]$window.ShowDialog()
