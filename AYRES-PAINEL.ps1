Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$core = Join-Path $root 'AyresDev.ps1'
$terminal = Join-Path $root 'AYRES-TERMINAL.ps1'

[xml]$xaml = @'
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="AYRES DEV // MASKED CONTROL"
  Width="1180" Height="720"
  MinWidth="980" MinHeight="620"
  WindowStartupLocation="CenterScreen"
  WindowStyle="None"
  ResizeMode="CanResizeWithGrip"
  AllowsTransparency="True"
  Background="Transparent">
  <Window.Resources>
    <Style x:Key="NeonCard" TargetType="Button">
      <Setter Property="Width" Value="168"/>
      <Setter Property="Height" Value="146"/>
      <Setter Property="Margin" Value="10"/>
      <Setter Property="Foreground" Value="#72FF9A"/>
      <Setter Property="Background" Value="#D9081010"/>
      <Setter Property="BorderBrush" Value="#5500FF62"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="FontFamily" Value="Consolas"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Card"
              Background="{TemplateBinding Background}"
              BorderBrush="{TemplateBinding BorderBrush}"
              BorderThickness="{TemplateBinding BorderThickness}"
              CornerRadius="5">
              <Border.Effect>
                <DropShadowEffect x:Name="Glow" BlurRadius="13" Color="#00FF62" Opacity="0.24" ShadowDepth="0"/>
              </Border.Effect>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Card" Property="Background" Value="#D9183A28"/>
                <Setter TargetName="Card" Property="BorderBrush" Value="#FF66FF99"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Card" Property="Background" Value="#FF245C38"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Background="#F7030808" BorderBrush="#9900FF62" BorderThickness="1" CornerRadius="4">
    <Border.Effect>
      <DropShadowEffect BlurRadius="24" Color="#00FF62" Opacity="0.25" ShadowDepth="0"/>
    </Border.Effect>
    <Grid>
      <Grid.Background>
        <RadialGradientBrush Center="0.5,0.42" RadiusX="0.7" RadiusY="0.8">
          <GradientStop Color="#241B6B3C" Offset="0"/>
          <GradientStop Color="#FA030808" Offset="0.68"/>
        </RadialGradientBrush>
      </Grid.Background>

      <Canvas IsHitTestVisible="False" Opacity="0.26">
        <TextBlock Text="01001101 01000001 01010011 01001011 01000101 01000100" Foreground="#00FF62" FontFamily="Consolas" FontSize="12" Canvas.Left="55">
          <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetProperty="(Canvas.Top)" From="-180" To="760" Duration="0:0:8"/>
          </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
        </TextBlock>
        <TextBlock Text="git.status(); codex.ready = true; system.local = true;" Foreground="#00FF62" FontFamily="Consolas" FontSize="12" Canvas.Left="390">
          <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetProperty="(Canvas.Top)" From="-330" To="760" Duration="0:0:11"/>
          </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
        </TextBlock>
        <TextBlock Text="10110010 00110101 11100010 01010101 00110011" Foreground="#00D9FF" FontFamily="Consolas" FontSize="11" Canvas.Left="860">
          <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard RepeatBehavior="Forever">
            <DoubleAnimation Storyboard.TargetProperty="(Canvas.Top)" From="-90" To="760" Duration="0:0:6"/>
          </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
        </TextBlock>
      </Canvas>

      <TextBlock Text="[  O  O  ]&#x0a; \  __  /&#x0a;  \____/"
        Foreground="#1500FF62" FontFamily="Consolas" FontWeight="Bold" FontSize="84"
        HorizontalAlignment="Center" VerticalAlignment="Center"
        TextAlignment="Center" IsHitTestVisible="False"/>

      <Grid Margin="34">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0">
          <StackPanel>
            <TextBlock Text="AYRES DEV // MASKED CONTROL" Foreground="#78FF9D" FontFamily="Consolas" FontSize="27" FontWeight="Bold"/>
            <TextBlock Text="LOCAL OPERATOR  |  PROJECTS  |  CODEX  |  GIT" Foreground="#6B98B8A5" FontFamily="Consolas" FontSize="12" Margin="1,7,0,0"/>
            <Rectangle Height="2" Width="410" Fill="#00FF62" HorizontalAlignment="Left" Margin="0,10,0,0"/>
          </StackPanel>
          <StackPanel HorizontalAlignment="Right" Orientation="Horizontal">
            <TextBlock x:Name="ClockText" Foreground="#7999FFB2" FontFamily="Consolas" FontSize="12" VerticalAlignment="Center" Margin="0,0,24,0"/>
            <TextBlock x:Name="MinimizeButton" Text="[ _ ]" Foreground="#00D9FF" FontFamily="Consolas" FontSize="14" Cursor="Hand" Margin="0,0,18,0"/>
            <TextBlock x:Name="CloseButton" Text="[ EXIT ]" Foreground="#FF5468" FontFamily="Consolas" FontSize="14" Cursor="Hand"/>
          </StackPanel>
        </Grid>

        <StackPanel Grid.Row="1" VerticalAlignment="Center">
          <TextBlock Text="SELECT OPERATION" Foreground="#A000D9FF" FontFamily="Consolas" FontSize="12" HorizontalAlignment="Center" Margin="0,0,0,18"/>
          <WrapPanel HorizontalAlignment="Center">
            <Button x:Name="ProjectsButton" Style="{StaticResource NeonCard}">
              <StackPanel>
                <TextBlock Text="[01]" Foreground="#00D9FF" FontSize="18" HorizontalAlignment="Center"/>
                <TextBlock Text="PROJECTS" Foreground="#72FF9A" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,16,0,7"/>
                <TextBlock Text="AYRES WORKSPACES" Foreground="#668CA092" FontSize="10" HorizontalAlignment="Center"/>
              </StackPanel>
            </Button>
            <Button x:Name="CodexButton" Style="{StaticResource NeonCard}">
              <StackPanel>
                <TextBlock Text="&lt;/&gt;" Foreground="#00D9FF" FontSize="25" HorizontalAlignment="Center"/>
                <TextBlock Text="CODEX" Foreground="#72FF9A" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,12,0,7"/>
                <TextBlock Text="AI IN THIS REPO" Foreground="#668CA092" FontSize="10" HorizontalAlignment="Center"/>
              </StackPanel>
            </Button>
            <Button x:Name="TerminalButton" Style="{StaticResource NeonCard}">
              <StackPanel>
                <TextBlock Text="&gt;_" Foreground="#00D9FF" FontSize="25" HorizontalAlignment="Center"/>
                <TextBlock Text="TERMINAL" Foreground="#72FF9A" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,12,0,7"/>
                <TextBlock Text="POWERSHELL LOCAL" Foreground="#668CA092" FontSize="10" HorizontalAlignment="Center"/>
              </StackPanel>
            </Button>
            <Button x:Name="CodeButton" Style="{StaticResource NeonCard}">
              <StackPanel>
                <TextBlock Text="{}{ }" Foreground="#00D9FF" FontSize="25" HorizontalAlignment="Center"/>
                <TextBlock Text="VS CODE" Foreground="#72FF9A" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,12,0,7"/>
                <TextBlock Text="EDIT AYRES DEV" Foreground="#668CA092" FontSize="10" HorizontalAlignment="Center"/>
              </StackPanel>
            </Button>
            <Button x:Name="GitHubButton" Style="{StaticResource NeonCard}">
              <StackPanel>
                <TextBlock Text="GIT" Foreground="#00D9FF" FontSize="23" HorizontalAlignment="Center"/>
                <TextBlock Text="GITHUB" Foreground="#72FF9A" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,12,0,7"/>
                <TextBlock Text="REMOTE REPOSITORY" Foreground="#668CA092" FontSize="10" HorizontalAlignment="Center"/>
              </StackPanel>
            </Button>
          </WrapPanel>
        </StackPanel>

        <Grid Grid.Row="2">
          <TextBlock x:Name="StatusText" Text="&gt; SYSTEM READY // WAITING FOR INPUT_" Foreground="#00FF62" FontFamily="Consolas" FontSize="13">
            <TextBlock.Triggers><EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard RepeatBehavior="Forever">
              <DoubleAnimation Storyboard.TargetProperty="Opacity" From="1" To="0.35" Duration="0:0:0.65" AutoReverse="True"/>
            </Storyboard></BeginStoryboard></EventTrigger></TextBlock.Triggers>
          </TextBlock>
          <TextBlock Text="SAFE LOCAL MODE // NO ADMIN" Foreground="#556C8174" FontFamily="Consolas" FontSize="11" HorizontalAlignment="Right"/>
        </Grid>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$status = $window.FindName('StatusText')

function Start-AyresScript {
  param([string]$ScriptPath, [string]$Extra = '')
  $args = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Extra"
  Start-Process powershell.exe -ArgumentList $args -WorkingDirectory $root
}

$window.FindName('CloseButton').Add_MouseDown({ $window.Close() })
$window.FindName('MinimizeButton').Add_MouseDown({ $window.WindowState = 'Minimized' })
$window.Add_MouseLeftButtonDown({
  if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
    try { $window.DragMove() } catch {}
  }
})
$window.FindName('ProjectsButton').Add_Click({
  $status.Text = '> OPENING PROJECT OPERATIONS...'
  Start-AyresScript -ScriptPath $core -Extra '-Mode Dashboard'
})
$window.FindName('CodexButton').Add_Click({
  $status.Text = '> STARTING CODEX IN AYRES REPOSITORY...'
  $safeRoot = $root.Replace("'", "''")
  Start-Process powershell.exe -WorkingDirectory $root -ArgumentList "-NoExit -NoProfile -Command `"Set-Location -LiteralPath '$safeRoot'; codex`""
})
$window.FindName('TerminalButton').Add_Click({
  $status.Text = '> OPENING LOCAL POWERSHELL...'
  Start-Process powershell.exe -WorkingDirectory $root -ArgumentList '-NoExit'
})
$window.FindName('CodeButton').Add_Click({
  if (Get-Command code -ErrorAction SilentlyContinue) {
    $status.Text = '> OPENING VS CODE...'
    Start-Process code -ArgumentList "`"$root`""
  } else {
    [System.Windows.MessageBox]::Show('VS Code nao foi encontrado neste PC.','AYRES DEV') | Out-Null
  }
})
$window.FindName('GitHubButton').Add_Click({
  $status.Text = '> OPENING GITHUB REMOTE...'
  Start-Process 'https://github.com/hakerdebh-commits/ayres-dev-terminal'
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({ $window.FindName('ClockText').Text = (Get-Date -Format 'dd/MM/yyyy  HH:mm:ss') })
$timer.Start()

[void]$window.ShowDialog()
