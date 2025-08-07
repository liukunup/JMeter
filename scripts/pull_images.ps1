# Power Shell

# Usage: .\pull_images.ps1 [-Sha <git_short_sha>]

param(
    [string]$Sha = ""
)

$COMMON_PARAMS = @{
    Registry = "docker.io"
    Jmeter = "5.6.3"
    ImageBase = "liukunup/jmeter"
    OS = @{
        Alpine = "alpine-3"
        Ubuntu = "ubuntu-24.04"
    }
    AlpineJRE = @{
        JDK21 = "openjdk21-jre"
        JDK8 = "openjdk8-jre"
    }
    UbuntuJRE = @{
        JDK21 = "openjdk-21-jre"
        JDK8 = "openjdk-8-jre"
    }
}

$IMAGES = @(
    # Alpine images
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.AlpineJRE.JDK21)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.AlpineJRE.JDK21)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.AlpineJRE.JDK8)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.AlpineJRE.JDK8)-plugins"

    # Ubuntu images
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK8)"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK8)-plugins"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)-fullstack"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)-x11"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)-vnc-novnc"
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.UbuntuJRE.JDK21)-rdp"
)

foreach ($IMAGE in $IMAGES) {
    $imageRef = "$($COMMON_PARAMS.Registry)/$IMAGE"
    if (-not [string]::IsNullOrEmpty($Sha)) {
        $imageRef += "-$Sha"
    }

    docker pull $imageRef
    if ($COMMON_PARAMS.Registry -ne "docker.io") {
        docker tag $imageRef "docker.io/$IMAGE"
        docker rmi $imageRef
    }
}
