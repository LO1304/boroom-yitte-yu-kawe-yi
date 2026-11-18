allprojects {
    repositories {
        google()
        mavenCentral()
    }
    tasks.configureEach {
        // AGP 9.3 Lint's CommentDetector calls JDK 21 List.removeLast() on JDK 17 hosts.
        if (name.startsWith("lintVital")) {
            enabled = false
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
