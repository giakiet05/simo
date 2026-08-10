void main() {
  var baseUrl = "https://api.groq.com/openai/v1/chat/completions";
  var endpoint = '${baseUrl.replaceAll(RegExp(r"/chat/completions$"), "")}/audio/transcriptions';
  print(endpoint);
}
