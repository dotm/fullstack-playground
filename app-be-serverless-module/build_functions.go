package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
)

func main() {
	functionList := getLambdaFunctionList()
	for _, functionName := range functionList {
		cmd := exec.Command("go", "build", "-o", fmt.Sprintf("dist/functions/%s", functionName), fmt.Sprintf("functions/%s/main.go", functionName))
		cmd.Env = os.Environ()
		cmd.Env = append(cmd.Env, "GOOS=linux")
		cmd.Env = append(cmd.Env, "GOARCH=amd64")
		_, err := cmd.Output()

		if err != nil {
			fmt.Println(err)
			return
		}
	}

	fmt.Printf("Finished compiling %d functions", len(functionList))
}

func getLambdaFunctionList() []string {
	files, err := ioutil.ReadDir("./functions")
	if err != nil {
		log.Fatal(err)
	}

	functionList := []string{}
	for _, f := range files {
		if f.IsDir() {
			functionList = append(functionList, f.Name())
		}
	}

	return functionList
}
