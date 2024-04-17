A working demo of an automated speech recognition system to process player requests and extract insights/entities/sentiment from the audio.

Many game studios (especially in India & ASEAN) want to build an ASR (automated-speech-recognition) system to supplement their player support & community management using AWS' services. Most Indians colloquially use English words/phrases interspersed with their regional language while speaking, the studios wondered if AWS' AI/ML services would still work in that scenario. Amazon Transcribe supports the ability to identify multiple languages in a given audio, and that capability has been demonstrated in this
simple ASR sample workflow PoC/demo (bash script), and give the studios a kick-start with the services.

Notes:
1. The util is available as-is. Download/copy the (raw) shell script – or clone the repo), preferably on a MacOSX or a Linux box
2. You should have AWS CLI setup & running in your bash/zsh shell, with permissions to S3, Transcribe, Translate, & Comprehend
3. The tool uses wget, jq and GNU CoreUtils (gtimeout) – please check that you have them installed, or replace in the script with an appropriate alternate util
4. You can use a [sample Input audio](https://github.com/squadrun/aws-marketplace-examples/blob/main/data/input/real-time/hinglish-example.mp3) or record/upload your own Hinglish audio (and other language mixed with English or other language words) & upload it to a S3 bucket in your account that you will supply to the script
5. Make the downloaded shell script executable (chmod +x asr-demo.sh) and execute it (./asr-demo.sh)
