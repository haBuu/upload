import React, { Component } from 'react';

class Progress extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div className="my-2">
        <p>{this.props.file} {'(' + this.props.value + '%)'}</p>
        <div className="progress">
          <div className="progress-bar progress-bar-striped bg-success" role="progressbar" style={{width: this.props.value + "%"}}></div>
        </div>
      </div>


    );
  }
}

export default Progress;
