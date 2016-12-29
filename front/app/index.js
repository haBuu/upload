import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

ReactDOM.render(
  <App api={'http://localhost:3000/'} path={''} />,
  document.getElementById('root')
);
