package main

import (
	"io/ioutil"
	"log"
	"os"

	"fmt"

	"encoding/json"

	"bytes"

	"os/exec"

	"github.com/ghodss/yaml"
)

func main() {

	fileName := os.Args[1]
	y, err := ioutil.ReadFile(fileName)
	if err != nil {
		log.Fatalf("reading yaml file: %v", err)
	}

	j, err := yaml.YAMLToJSON(y)
	if err != nil {
		log.Fatalf("converting yaml to json: %v", err)
	}
	var out bytes.Buffer
	err = json.Indent(&out, j, "", "  ")
	if err != nil {
		log.Fatalf("indenting json: %v", err)
	}

	header := fmt.Sprintf(`local opencompose = import "lib/opencompose.libsonnet";
function(params={}, namespace="default")

opencompose.createServices(%s)`, string(out.Bytes()))

	// create a file
	t := []byte(header)
	err = ioutil.WriteFile("tmp.libsonnet", t, 0644)
	if err != nil {
		log.Fatalf("creating tmp file: %v", err)
	}

	// operate on it
	var op []byte
	if op, err = exec.Command("/home/hummer/.local/bin/jsonnet", "tmp.libsonnet").Output(); err != nil {
		log.Fatalf("executing command: %v", err)
	}
	// delete it
	defer os.Remove("tmp.libsonnet")

	y, err = yaml.JSONToYAML(op)
	if err != nil {
		log.Fatalf("json to yaml conversion: %v", err)
	}
	fmt.Printf("%s\n", string(y))
}
