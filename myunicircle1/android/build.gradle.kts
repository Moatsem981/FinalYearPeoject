// ✅ Make sure the repositories are inside buildscript and allprojects
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.3") // ✅ Latest version
        classpath("com.google.gms:google-services:4.3.15") // ✅ Required for Firebase
    }
}

// ✅ Ensure all projects can access Firebase dependencies
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Ensure the correct build directory setup
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
