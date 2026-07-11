import { ok } from '@hackathon/shared';

export default function Home() {
  const status = ok({ message: 'Client is running' });
  return (
    <div>
      <h1>Hackathon App</h1>
      <p>Status: {status.data?.message}</p>
    </div>
  );
}
