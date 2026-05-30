## Create a safe environment to run pi
Agentic models may delete all of your files or copy secrets. It is important to run them inside an isolated environment 
e.g. Virtual Machine, Docker container

## Install pi.dev
Inside your isolated environment install pi,

<pre>
curl -fsSL https://pi.dev/install.sh | sh
</pre>

Full install instructions at [pi.dev](pi.dev)

## Get a current model name and API Key from Lumen

* If you don't have a key yet, login and  create a Lumen API key. You can create keys either directly under your own [profile](https://lumen.ncsa.illinois.edu/profile) or as a [client](https://lumen.ncsa.illinois.edu/clients) project.

* Store this key in an environment variable e.g., <pre>export LUMEN_NCSA_KEY=<em>yourkey</em></pre>

* Add the above export line to your .bashrc or equivalent

## Select a current Lumen model

View and select an agentic model,
https://lumen.ncsa.illinois.edu/models
The model page can also tell you the max context size

## Create a model json file ("~/.pi/agent/models.json) for pi.dev
Example below.
<pre>
{
  "providers": {
    "lumen": {
      "baseUrl": "https://lumen.ncsa.illinois.edu/v1",
      "apiKey": "${LUMEN_NCSA_KEY}",
      "api": "openai-completions",
      "compat": {
        "supportsDeveloperRole": false
      },
      "name": "Lumen",
      "models": [
        {
          "id": "qwen3.6-35b-a3b",
          "name": "qwen3.6-35b-a3b",
          "contextWindow": 262144,
          "maxTokens": 262144,
          "input": ["text","image"],
          "reasoning": true
        }
      ]
    }
  }
}
</pre>

## Select and run the model

<pre>
mkdir playpen
cd playpen
pi
</pre>

Then test it,

<pre>
/model
Write a file "poem.txt" about using agentic models to create code 
Create a python project
</pre>
