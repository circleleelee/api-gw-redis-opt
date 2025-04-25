import http from 'k6/http';
export let options = { vus: 100, duration: '30s' };
export default () => http.post('http://localhost:8000/api', '{}',
  { headers: { 'Content-Type': 'application/json' }});