import http from 'k6/http';
import { check } from 'k6'; // Import check

export let options = { vus: 100, duration: '30s' };

export default function () {
  // Change to GET and use a potentially valid path like /api/
  const res = http.get('http://3.239.159.10:8000/api/');

  // Add a check to explicitly see the status code distribution
  check(res, {
    'status is 200': (r) => r.status === 200,
    'status is 404': (r) => r.status === 404,
    'status is 500': (r) => r.status === 500,
    // Add other status codes you might expect
  });
}