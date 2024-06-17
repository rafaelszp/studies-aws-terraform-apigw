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
  const ip = {ip: await ipget.json()};
  
  const response = {
    statusCode: 200,
    body: ip,
    headers: {"content-type": "application/json"} 
  };
  return response;
};
