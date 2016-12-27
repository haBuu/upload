import React, { Component } from 'react';

class Breadcrumbs extends Component {
  constructor(props) {
    super(props);
    this.subPath = this.subPath.bind(this);
    this.isEmpty = this.isEmpty.bind(this);
  }

  isEmpty(item) {
    return item.length > 0;
  }

  subPath(part) {
    const path = this.props.path;
    return path.substring(0, path.search(part) + part.length);
  }

  render() {
    const pathParts = this.props.path.split('/').filter(this.isEmpty);
    const breadcrumbs = pathParts.map((part) =>
      <li className="breadcrumb-item" key={this.subPath(part)}>
        <a type="button" onClick={this.props.navigate.bind(this, this.subPath(part))}
          href={'?path=' + this.subPath(part)}>
          {part}
        </a>
      </li>
    );
    return (
      <ol className="breadcrumb mt-1">
        <li className="breadcrumb-item">
          <a onClick={this.props.navigate.bind(this, '')}
            href=''>
            Home
          </a>
        </li>
        {breadcrumbs}
      </ol>
    );
  }
}

export default Breadcrumbs;
