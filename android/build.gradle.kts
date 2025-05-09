buildscript {
    extra["kotlin_version"] = "1.8.10"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${rootProject.extra["kotlin_version"]}")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
    project.evaluationDependsOn(":app")
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.activity:activity:1.8.2")
            force("androidx.activity:activity-ktx:1.8.2")
            force("androidx.appcompat:appcompat:1.6.1")
            force("androidx.window:window:1.2.0")
            force("androidx.window:window-java:1.2.0")
            force("androidx.lifecycle:lifecycle-runtime:2.7.0")
            force("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
            force("androidx.fragment:fragment:1.6.2")
            force("androidx.fragment:fragment-ktx:1.6.2")
            force("androidx.browser:browser:1.7.0")
        }
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}