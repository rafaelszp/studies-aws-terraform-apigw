const IPIFY_URL=process.env.IPIFY_URL

export const handler = async (event) => {
  // TODO implement
  

  
  /*global fetch*/
  console.log("fetching",IPIFY_URL)
  const ipget = await fetch(IPIFY_URL);
  const ip = {ip: await ipget.json()};
  
  const response = {
    statusCode: 200,
    body: ip,
    headers: {"content-type": "application/json"} 
  };
  return response;
};
