import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders hello world message', () => {
  render(<App />);
  const textElement = screen.getByText(/hello world of vulnerabilities/i);
  expect(textElement).toBeInTheDocument();
});
