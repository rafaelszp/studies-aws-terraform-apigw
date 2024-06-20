import { InvokeCommand, LambdaClient, LogType } from "@aws-sdk/client-lambda";

const IPIFY_URL=process.env.IPIFY_URL

export const handler = async (event) => {
  
  const clientIP = event.headers ? event.headers['x-forwarded-for']:undefined;
  const headers = {}
  if(clientIP){
    headers["x-forwarded-for"] = clientIP
  }
  
  /*global fetch*/
  console.log("fetching",IPIFY_URL)
  const ipget = await fetch(IPIFY_URL,headers);
  const ip = await ipget.json();

  console.log(ip)

  const resp_country =  JSON.parse(await invokeCountry(ip.ip))

  const ipInfo = {
    ip: ip.ip,
    "country": resp_country.body
  };

  const response = {
    statusCode: 200,
    "isBase64Encoded": false,
    body: JSON.stringify(ipInfo),
    headers: {"content-type": "application/json"} 
  };
  return response;
};

const invokeCountry = async (ip) => {

  console.log(`Searching country for ip ${ip}`)
  const client = new LambdaClient({});
  const command =  new InvokeCommand({
    FunctionName: "lambda_country_finder",
    LogType: LogType.Tail,
    Payload: JSON.stringify({clientIP: ip})
  });

  const { Payload, LogResult } = await client.send(command);
  const result = Buffer.from(Payload).toString();
  const logs = Buffer.from(LogResult, "base64").toString();

  console.log({response_country: Payload})

  return result

}
