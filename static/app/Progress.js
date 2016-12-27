import React, { Component } from 'react';

class Progress extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div className="mt-1">
        <p>{this.props.file} {'(' + this.props.value + '%)'}</p>
        <progress className="progress-striped progress progress-success"
          value={this.props.value} max="100">
        </progress>
      </div>
    );
  }
}

export default Progress;
