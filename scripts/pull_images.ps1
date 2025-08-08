# Power Shell

# Usage: .\pull_images.ps1 [-SHA <git_short_sha>]

param(
    [string]$SHA = ""
)

$COMMON_PARAMS = @{
    Registry = "docker.io"
    Jmeter = "5.6.3"
    ImageBase = "liukunup/jmeter"
    OS = @{
        Alpine = "alpine-3"
        Ubuntu = "ubuntu-24.04"
    }
    JRE = @{
        JDK21 = "openjdk-21-jre"
        JDK8 = "openjdk-8-jre"
    }
}

$IMAGES = @(
    # Alpine images
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK21)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK21)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK8)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK8)-plugins"

    # Ubuntu images
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK8)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK8)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-fullstack"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-x11"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-vnc-novnc"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-rdp"
)

foreach ($IMAGE in $IMAGES) {
    $imageRef = "$($COMMON_PARAMS.Registry)/$IMAGE"
    if (-not [string]::IsNullOrEmpty($SHA)) {
        $imageRef += "-$SHA"
    }

    docker pull $imageRef
    if ($COMMON_PARAMS.Registry -ne "docker.io") {
        docker tag $imageRef "docker.io/$IMAGE"
        docker rmi $imageRef
    }
}
