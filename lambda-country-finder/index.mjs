const COUNTRY_FINDER_URL = process.env.COUNTRY_FINDER_URL

export const handler = async (event) => {

  const clientIP = event.clientIP ? event.clientIP : '0.0.0.0'

  /*global fetch*/ 
  const countryAPI = await fetch(`${COUNTRY_FINDER_URL}/${clientIP}`)
  const country = await countryAPI.text()

  return {
    statusCode: 200,
    body: JSON.stringify(country)
  }
}